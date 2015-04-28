# encoding: utf-8

%w( jimports ).each {|dep| require_relative dep }



#
# Here I define a simple convenience class for running code blocks
# in a concurrent, threaded context.
# This allows us to say “Concurrent.ly do ... end”
# which furthers the tradition of highly-expressive Ruby syntax.
# 
# In its implementation here, JRuby is required for its Executors.
# We could use Ruby Threads, which naturally expand to real threads
# in a Java context, but then we would not get the optimizations
# provided by a thread pool.
# We really could change out this implementation without any real
# impact on the calling code.
# 



class Concurrent
    
    #
    # The double-at @@ syntax denotes class variables.
    # Note how the ruby_style_method_name can be used
    # in place of the javaStyleMethodName():
    # 
    @@pool = JavaConcurrent::Executors.new_cached_thread_pool
    
    
    #
    # Start class method definitions:
    # 
    class << self
        
        #
        # Class method `ly`
        # is passed a block (the do..end syntax
        # in the calling context) which we don't explicitly
        # see as a parameter here.
        # 
        def ly
            
            # We pass a block to the java thread pool
            # in the submit() method. Note this block is converted
            # on-the-fly to a new Callable, automatically.
            @@pool.submit do
                
                begin
                    
                    # What this concurrent block does is to itself
                    # run block that the caller passed to the ‘ly’
                    # method. This is done using the “yield” keyword:
                
                    yield
                    
                    
                rescue Exception => except
                    # If any uncaught exceptions were raised on
                    # the concurrent task, print them out and allow
                    # the task to exit.
                    puts except.inspect
                    puts except.backtrace
                    
                end # begin/rescue
                
            end # concurrent block
            
        end # ly method
        
        
    end # class methods
    
end # Concurrent class
