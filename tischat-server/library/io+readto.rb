# encoding: utf-8


#
# A Category on IO
# which adds a read_to method.
# This allows us to easily ask for all stream data up to a particular
# string, in much the same way that readline works---but for any arbitrary
# character (like, say, EOT?) rather than just \n.
# 


class IO
    
    # Assumes TOTE.
    
    def read_to endstr=$/
        cumulative = "".force_encoding TOTE
        
        # This method is not particularly fast, in that it reads and compares
        # one char at a time in Rubyland.
        
        loop do
            cumulative << self.readchar
            return cumulative if cumulative.end_with? endstr
        end
        
        
    rescue EOFError
        # At the end of the stream, (which is not likely in this context),
        # return all we have up to this point. Now, if the stream was
        # actually broken, a different error would be raised, which
        # would cascade up to the caller.
        
        return cumulative
    end
    
end