# encoding: utf-8



#
# The ClientAcceptor is the “Start Center” of the server.
# It spins up a TCP server, accepts requests, and passes
# each one off to a new ClientHandler.
# 




# The Rubyist way of requiring/importing files.
# The “%w()” syntax means “split on whitespace into words”;
# then on .each word, called “dep,” require it.
# “require_relative” is used for local files.

%w( java socket ).each {|dep| require dep }
%w( Concurrent MessageDispatch ClientHandler ).each {|dep| require_relative dep }



class ClientAcceptor
    
    
    def initialize port=4020
        
        #
        # The @ notation indicates an instance variable.
        @servlet = TCPServer.new port
        
    end
    
    
    #
    # Listen for incoming connections.
    # This method blocks and loops forever,
    # or until the TCP server breaks.
    # 
    def listen
        puts "Server up"
        
        loop do
            client = @servlet.accept  # Blocks for incoming clients.
            
            #
            # Once we get a client, the first thing we need to do
            # is set our understanding of the text encoding
            # to the expected, correct value.
            # (Recall TOTE is UTF-8, or “The Only Text Encoding.”)
            client.set_encoding(TOTE)
            
            #
            # Now that that's done, we can pass off the connection
            # to another thread:
            Concurrent.ly do
                handler = ClientHandler.new client
                MessageDispatch.hub.adopt handler
            end
            
            # Note that this is a relatively short-lived thread---
            # it exists only to gather '/login' info from the
            # client. Once that's done, the ClientHandler itself
            # is responsible for scheduling its own operations.
            
            
        end # forever loop
        
    end # listen method
    
    
    
    
    
end # class
