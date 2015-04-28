# encoding: utf-8

require 'java'
%w( MessageDispatch Transmission Concurrent errors jimports ).each {|dep| require_relative dep }




#
# A ClientHandler is responsible for maintaining communications with a single
# TISCaP client.
# 
# It has an outbox that queues up all outgoing transmissions to the client,
# so that calls for the handler to receive such communications return summarily.
# It also maintains the persistent reference to the I/O stream connected
# to the client; and is itself referenced by the MessageDispatch Hub.
# 
# The Handler's “run loop,” so to speak, consists of two parallel threads,
# each started by the #talk method.
# 



class ClientHandler
    
    
    
    def initialize io_stream
        
        # Initialization blocks for the name to be retrieved,
        # so handler creation is done on its own concurrent block.
        
        # The outbox queue is a Linked Blocking Deque from Java.
        # I chose a Deque because I can insert premature halting
        # sentinels in front of other messages.
        @outbox = JavaConcurrent::LinkedBlockingDeque.new
        
        # ⎛In Ruby, the TCP connection is an instance of the IO class.⎞
        # ⎜This means, with no effort, we get a rich library of all   ⎟
        # ⎜sorts of different reading and scanning and writing methods⎟
        # ⎝on a single, uncomplicated object.                         ⎠
        @iost = io_stream
        
        # To start, set @accepting to false, to bounce early messages
        # off. After login, this is true.
        @accepting = false
        
    end
    
    
    
    #
    # Is the handler active?
    # Active is defined as whether the receiver
    # has a(n apparently) working I/O stream.
    # 
    def active?
        
        # ⎛A scope in Ruby (incl. this method) always evaluates⎞
        # ⎝to its last expression.                             ⎠
        
        (!@iost.nil?)  &&  (!@iost.closed?)
    end
    
    
    
    #
    # Quickly terminate the connection to the client.
    # Close, and if the closing can't be done, let the
    # garbage collector have at the I/O stream.
    # 
    def kill
        @accepting = false
        @iost.close  rescue nil  # force termination now
        @iost = nil
    end
    
    
    
    #
    # Gracefully close the connection with the client.
    # Allow all pending messages to go through (but don't accept
    # any more); and when they're done, let the run loop stop itself.
    # 
    def graceful
        @accepting = false
        @outbox.put HaltTransmission
        
        # When the outbox-loop encounters the HaltTransmission,
        # it will break itself and close the connection.
        # See also the end of the #talk method.
        
    end
    
    
    
    #
    # Write a well-defined error to the client.
    # Expects an instance of a class defined in errors.rb.
    # 
    def error tiscap_error
        return unless @accepting
        @outbox.put tiscap_error.transmission
    end
    
    
    
    
    #
    # Let the client receive a message.
    # Accepts either a string for a message, where the from
    # and public arguments are set, or an already-prepared
    # TiscapTransmission.
    # 
    def receive message, from=nil, public=false
        raise GeneralTiscapError.new "User “#{self.name}” not available." unless @accepting
        
        transmission = message
        
        # If the message is not yet a Transmission,
        # make it one:
        
        unless transmission.is_a? TiscapTransmission
            # It's just a text message. Package it up!
            verb = if public  then :']public'  else :']private'  end
            transmission = TiscapTransmission.new( verb, from, message )
        end
        
        # Throw it on the outbox!
        @outbox.put transmission
    end
    
    
    
    
    
    
    #
    # Starts regular I/O with the actual client.
    # This method spins up two threads, one for listening to,
    # and one for writing on. Each thread acts as a run loop,
    # blocking for events. The listener blocks for communication on
    # the wire, and the writer blocks for messages to be enqueued
    # on the @outbox.
    # 
    def talk
        
        #
        # The Listening Proc
        # 
        # This proc loopingly accepts a piping hot TiscapTransmission,
        # interprets it, and acts upon it. It almost never exits by itself,
        # but will sometimes call #graceful to cause itself to be
        # indirectly terminated.
        # 
        Concurrent.ly do
            
            loop do
                begin  # like ‘try’
                    
                    # If we're no longer accepting, stop reading now.
                    break unless @accepting
                    
                    # Pull a Transmission off the wire.
                    # Execution usually waits here.
                    received = TiscapTransmission.from @iost
                    
                    # Now that we have a transmission, interpret it
                    # based on the verb at hand:
                    
                    case received.verb
                        
                    when :'/private'  # Deliver a private message.
                        
                        raise BadSyntaxError.new unless username_arg_ok? received.argument
                        raise BadSyntaxError.new if received.data.nil?
                        
                        # all messages go over the MessageDispatch Hub.
                        MessageDispatch.hub.send_private received.argument, received.data, self.name
                        
                        
                    when :'/public'  # Broadcast a public message.
                        
                        raise BadSyntaxError.new unless received.argument.nil?
                        raise BadSyntaxError.new if received.data.nil?
                        
                        # even public messages go over the MessageDispatch Hub.
                        MessageDispatch.hub.send_public received.data, self.name
                        
                        
                    when :'/users'  # Prepare and send back the active user list.
                        
                        response = TiscapTransmission.new( :']activeusers',
                            MessageDispatch.hub.users.join(','),
                            nil )
                        self.receive response
                        
                        
                    when :'/close'  # Close the connection.
                        
                        self.graceful
                        
                        
                    else  # probably a server verb. not cool.
                        raise BadSyntaxError.new
                        
                        
                    end
                    
                    
                    # Mitigate overrunning the whole machinery, and don't
                    # accept more data for a little bit:
                    sleep 0.25
                    
                    
                    
                rescue TiscapError => you_fucked_up
                    # Syntax errors raised above land here.
                    # These can be written to the client, and then ignored.
                    self.error you_fucked_up
                    
                rescue EOFError, IOError, SystemCallError => goodbye
                    # I/O problems land here, as in when the input stream
                    # gets terminated. We could kill the connection,
                    # but it might not be so dire; and the #graceful procedure
                    # is robust enough to bail out of an already-dead stream.
                    self.graceful
                    break
                    
                rescue NoMethodError, JavaLang::NullPointerException => to_err
                    # An error I haven't yet caught will hopefully land here,
                    # barf its backtrace, and cause the handler to stop reading
                    # from the client.
                    puts to_err.inspect
                    puts to_err.backtrace
                    break
                    
                end # try
            end # loop
            
        end # thread
        
        
        
        
        #
        # The Writing Proc
        # 
        # This proc loopingly waits for things to say (in the @outbox)
        # and---gasp!---writes them out to the client. It's this proc
        # which is responsible for executing a graceful shutdown of the
        # connection. When it receives a HaltTransmission in the @outbox,
        # it breaks its run loop, closes the I/O stream, and instructs
        # the MessageDispatch Hub to disown the handler, thereby re-
        # moving itself from the chat circle.
        # 
        Concurrent.ly do
            
            loop do
                begin
                    
                    # We don't break if inactive,
                    # because we might have a few more messages to shove down the pipe.
                
                    toGo = @outbox.take
                    break if toGo.is_last?   # Graceful shutdown
                
                    @iost.write toGo.representation
                
                rescue EOFError, IOError, SystemCallError => goodbye
                    # When the I/O stream breaks, we land here.
                    # Just hop out of the loop for cleanup.
                    break
                    
                rescue NoMethodError, JavaLang::NullPointerException => to_err
                    # Uh-oh. I missed something. Better fix it...
                    # but first, break the connection.
                    puts to_err.inspect
                    puts to_err.backtrace
                    break
                    
                end # try
            end # loop
            
            
            #
            # As soon as the write-loop ends, break the pipe altogether:
            @iost.close  rescue nil
            
            #
            # And then tell MessageDispatch to disown us:
            MessageDispatch.hub.disown self
            
            
        end # thread
       
       
        
    end # talk method
    
    
    
    
    
    #
    # The chosen username of the client.
    # 
    # This is an absurdly-complicated method, as it has to take into account
    # several circumstances. First, @name may not yet have been set. If it
    # hasn't, we need to do so. To do that, we literally just wait for
    # the client to enter the appropriate /login command. If they do it im-
    # properly, we set the name to THE EMPTY STRING and re-raise.
    # After either case, we need to begin accepting transmissions, so that
    # either good data or error messages can be delivered to the client.
    # 
    def name
        unless @name
            begin
                @name = get_login
            rescue TiscapError => toki_doki
                @name = ''
                raise toki_doki
            ensure
                @accepting = true
            end
        end
        
        @name
        
        # We can fairly assume that no one will concurrently ask for our name
        # until this method returns for the first time.
    end
    
    
    
    
    
    
    private
    
    
    #
    # Using Transmission.from, this method blocks on the io-stream
    # until it finds the right Transmission. If an invalid or unexpected
    # one comes in, we raise an Error and hope the caller knows what
    # to do with it.
    # Returns the client's desired username.
    # 
    def get_login
        loginCommand = TiscapTransmission.from @iost
        raise BadSyntaxError.new unless loginCommand.verb == :'/login'
        raise BadSyntaxError.new unless username_arg_ok?(loginCommand.argument)
        # raise BadSyntaxError.new unless loginCommand.data.nil?  # impossible
        
        return loginCommand.argument
    end
    
    
    
    #
    # Checks whether the given username is OK.
    # 
    def username_arg_ok? username
        return false if username.nil?
        return false unless (1..16) === username.length
        return false unless username.match /\A[0-9a-zA-Z]*\z/
        
        # oh? okay, all good.
        true
    end
    
    
    
end
