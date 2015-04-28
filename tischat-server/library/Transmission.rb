# encoding: utf-8

%w( errors string+insensitivity io+readto ).each {|dep| require_relative dep }




#
# TiscapTransmissions provide a structured container for the concept
# of a “Transmission” according to the TISCaP terminology: that is,
# an atomic communication from server-to-client or client-to-server
# consisting of a verb, associated argument, and associated data.
# 
# Transmissions can be (and often are) constructed directly in the code,
# when the Server thinks of something it needs to say to the client.
# They can then generate their correct data representation for writing out.
# But the class also provides a constructor which interprets a Transmission
# by reading from an I/O stream.
# 




class TiscapTransmission
    
    #
    # First we define a few handy Klass Konstants.
    # 
    # Verbs, in their canonical internal representation, are
    # lowercase Symbols. A Ruby Symbol is a fast, immutable string,
    # which has only one instance identical to itself in the runtime.
    # A symbol starts with a colon and, if it contains special characters
    # like /slash or ]bracket, must be contained in single-quotes.
    # 
    
    # A Transmission guarantees it will only represent one of these actions:
    
    KnownVerbs = [
        :'/login',
        :'/users',
        :'/public',
        :'/private',
        :'/close',
        :']welcome',
        :']usernametaken',
        :']connected',
        :']disconnected',
        :']activeusers',
        :']public',
        :']private',
        :']error',
        :']badsyntax'
    ]
    
    
    # These verbs are the ones which expect data, and which
    # trigger the stream reader to go looking for data:
    
    VerbsWhichTakeData = [ :'/public', :']public', :'/private', :']private' ]
    
    
    # And finally, our lovable, friendly, fuzzy End-Of-Transmission character
    # (in UTF-8, of course.)
    
    EOT = "\u0004".force_encoding(TOTE)
    
    
    
    
    
    #
    # Begin Class Methods!
    # 
    class << self
        
        
        #
        # Transmission.from iostream
        # constructs a Transmission by reading from the i/o stream.
        # 
        # This method blocks for more input to become available, and
        # only returns when (a) it has received a complete Transmission,
        # or (b) when the i/o stream is broken or a syntax error is
        # encountered. Beware that the latter raises whatever exception
        # caused the stream to break.
        # 
        def from iostream
            
            #
            # Read a single line for command.
            # Parse out verb and argument.
            # Let verb dictate whether we then read data.
            
            
            command = iostream.readline.chomp
            
            #
            # Separate the verb from the argument on the first
            # space. If there is no space, there is no argument:
            
            textVerb, argument = command.split(/ /, 2)  # max. 2 pieces
            raise BadSyntaxError.new  if textVerb.nil?  # argument will be nil if none given
            
            #
            # Use lowercase verb as internal canonical representation.
            # Raise if not understood.
            
            verb = textVerb.downcase.to_sym#bol
            raise BadSyntaxError.new  unless KnownVerbs.include? verb
            
            #
            # Read the associated data, if it's expected:
            
            data = nil
            if VerbsWhichTakeData.include? verb
                data = iostream.read_to EOT
                data.chomp! EOT  # trim the EOT off the end
            end
            
            #
            # If all went well, make and return the Transmission:
        
            return self.new verb, argument, data
        
        
        end # from
        
    
    end # class methods
    
    
    
    
    
    #
    # Provide methods verb, argument, data
    # which read (but cannot modify) instance variables of the same name:
    
    attr_reader :verb, :argument, :data
    
    
    
    
    #
    # Check and set the relevant information
    # given to the Transmission.
    # Transmissions are immutable once created.
    # 
    # Verb must be one of the KnownVerbs.
    # Argument and Data may either be nil or Strings.
    # 
    def initialize verb, argument, data
        super()
        
        # Check the args:
        raise ArgumentError.new "Bad Verb"  unless KnownVerbs.include? verb
        raise ArgumentError.new "Bad Argument"  unless argument.nil? || argument.is_a?(String)
        raise ArgumentError.new "Bad Datums"  unless data.nil? || data.is_a?(String)
        
        # Duplicate the strings to preserve immutability:
        argument = argument.dup unless argument.nil?
        data = data.dup unless data.nil?
        
        # Set the iVars:
        @verb = verb
        @argument = argument.freeze
        @data = data.freeze
        
    end
    
    
    
    #
    # Construct the TISCaP representation of the Transmission,
    # suitable for sending directly to a client.
    # 
    def representation
        # Convert verb from symbol to mutable string
        accum = @verb.to_s
        
        # Append a space and the argument, iff given.
        accum << " " << @argument  unless @argument.nil?
        
        # Always append CRLF
        accum << "\r\n"
        
        # Append associated data and EOT, iff given.
        accum << @data << EOT  unless @data.nil?
        
        
        # Result is
        accum
    end
    
    
    
    #
    # Define that there may be more Transmissions to come
    # (this is not a terminal transmission).
    # 
    def is_last?
        false
    end
    
    
    
    
end






#
# The EndOfQueueTransmission is a noöp transmission that cannot
# actually be sent to the client. Its identity, however, marks
# the symbolic terminus of any outbox queue that contains it.
# 
# More to the point, when a ClientHandler encounters an EndOfQueueTransmission,
# it closes its i/o stream and terminates its threads.
# 
class EndOfQueueTransmission < TiscapTransmission
    
    #
    # If the representation is accidentally called for,
    # make sure it's something a little bit meaningful:
    # 
    def initialize
        super :']error', '', nil
    end
    
    
    #
    # Define that, unlike regular Transmissions,
    # there will not be any more after this one:
    # 
    def is_last?
        true
    end
    
end




#
# Also, define a single HaltTransmission, which can be used
# in place of creating a new EndOfQueueTransmission each time
# one is needed.
# 
HaltTransmission = EndOfQueueTransmission.new


