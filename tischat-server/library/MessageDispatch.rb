# encoding: utf-8
require 'java'
%w( ClientHandler ClientAcceptor jimports errors ).each {|dep| require_relative dep }




#
# MessageDispatch is the place where everything happens.
# 
# Contains the Chat Circle, and routes public and private messages.
# Usually only the singleton MessageDispatch.hub will be used.
# 




class MessageDispatch
    
    
    #
    # This weird syntactic beast defines class methods:
    # 
    class << self
        
        #
        # The set_up method must be called
        # before the message hub can be used.
        # This may not be strictly necessary, but
        # I'll have time to figure out a clever solution later.
        # 
        def set_up
            @@message_hub = MessageDispatch.new
        end
        
        
        #
        # Returns the singleton hub.
        # 
        def hub
            @@message_hub
        end
        
        
    end # class method defs
    
    
    
    def initialize
        super
        
        # The chat circle is modeled by a Concurrent Hash Map
        # of usernames to ClientHandlers. This provides excellent
        # concurrent behavior---see why in the #adopt method.
        
        @circle = JavaConcurrent::ConcurrentHashMap.new  # the defaults are sensible here.
    end
    
    
    
    #
    # Broadcast a public message to all connected clients.
    # 
    # Loops through all clients and delivers to each one.
    # This method gets called on the read thread of the client
    # who sent the message; but since messages are delivered very
    # quickly into each outbox, this is not a problem.
    # 
    def send_public text, from
        
        # Given each (username, ClientHandler pair)...
        @circle.each do |username, receiver|
            receiver.receive text, from, true  # true means public
        end
        
        # (And yes, this syntax works on a Java Concurrent HashMap.)
    end
    
    
    
    #
    # Send a private message to one specific client.
    # 
    # Uses the dictionary functionality to route the message
    # with impressive speed.
    # Throws back to the client if the user is not known.
    # 
    def send_private to, text, from
        receiver = @circle.get to  # A literal Java method call
        
        raise GeneralTiscapError.new "No known user “#{to}”" if receiver.nil?
        
        receiver.receive text, from, false  # false for not public
    end
    
    
    
    #
    # Ask a client to decide on its name,
    # and then either accept it into the chat circle,
    # or turn it away via ]usernametaken.
    # 
    def adopt client_handler
        
        # The following blocks for login,
        # and throws on bad username:
        name = client_handler.name
        
        # Okay, I love this method to death. Atomically shove the
        # client into the dictionary, but only if another user
        # hasn't already claimed that spot in the chat circle.
        # 
        # Did I mention it's atomic and threadsafe?
        
        result = @circle.put_if_absent name, client_handler
        
        # Now,
        # did it go in?
        
        unless result.nil?
            # There was already someone by that name.
            client_handler.error UsernameTakenError.new
            client_handler.graceful
            
            return  # Hits the ‘ensure’ block on its way out.
        end
        
        
        
        # All's well for a new user.
        # Welcome them!
        
        client_handler.receive TiscapTransmission.new( :']welcome', nil, nil )
        
        
        # The protocol leaves it up to the server, if it wants to push
        # an active users list. I'd rather not decide, so I'm leaving
        # it up to chance:
        if rand(2) == 1
            client_handler.receive TiscapTransmission.new( :']activeusers',
                                        self.users.join(','),
                                        nil )
        end
        
        
        # Broadcast the successful arrival of
        # this esteemed user:
        self.send_public(
            TiscapTransmission.new(:']connected', name, nil),
            nil)
        
        
        
    rescue TiscapError => you_eeediot
        # Some sort of client-understantable error. Pass it on to them.
        # That said, they haven't successfully logged in, so
        # we terminate the Transport connection as soon as the
        # error messages go out.
        
        client_handler.error you_eeediot
        client_handler.graceful
        
    ensure
        # ⎛This ALWAYS gets executed before the method terminates,⎞
        # ⎝even on early return!                                  ⎠
        
        # Even if we return early, we must---MUST!---let the
        # client handler open up its communication queues
        # so that error messages properly filter down to the client.
        # Were circumstances to require that communications never
        # open, we could do client_handler.kill before returning.
        
        client_handler.talk
        
    end
    
    
    
    
    
    #
    # Remove the logging-out client handler from the chat circle.
    # 
    # Don't remove them, though, if they're not literally present
    # in the circle already: there might be an entry in their name,
    # but they might be in the middle of being turned away, and we
    # can't have them clobbering the user whose same name is already
    # in the circle.
    # 
    def disown client_handler
        name = client_handler.name
        
        # No need to disown if they're not present.
        # ⎛I realize this is not strictly threadsafe.    ⎞
        # ⎝At this point, I also don't particularly care.⎠
        connectedHandler = @circle.get name
        return unless client_handler.equal? connectedHandler
        
        @circle.remove name
        
        
        # Broadcast their departure:
        # (Name may be THE EMPTY STRING if the user never successfully logged in.)
        if name.length > 0
            self.send_public(
                TiscapTransmission.new(:']disconnected', name, nil),
                nil)
        end
    end
    
    
    
    
    #
    # Return the array of all usernames currently present
    # in the chat circle.
    # 
    def users
        @circle.keySet.to_a
    end
    
    
    
    
    
end





# This guarantees that the singleton is set up as soon
# as the class is loaded.

MessageDispatch.set_up
