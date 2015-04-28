# encoding: utf-8


#
# A Category on String
# which allows more convenient checking of case-insensitive equality.
# 

class String
    
    #
    # Behaves much like Java's String#equalsIgnoreCase().
    # It's built on Ruby's String#casecmp, except that it returns
    # false when compared to nil, rather than raising an exception.
    # 
    def eql_igncase? other
        return false unless other.class == self.class
        self.casecmp other
    end
    
end
