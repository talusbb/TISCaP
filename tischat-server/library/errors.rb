# encoding: utf-8

require_relative 'Transmission'



#
# Here I define a small family of errors specific to the TISCaProtocol.
# They correspond fairly obviously to the three error transmissions,
# and inherit from a shared semiabstract TiscapError which hooks into
# the Ruby hierarchy of errors at StandardError.
# 
# TiscapErrors are handy in that they are exceptions that generate their
# own TiscapTransmissions, which can be sent directly to clients.
# 



#
# An abstract TiscapError is a StandardError,
# and is thereby an exception.
# 
class TiscapError < StandardError
    def transmission
        raise NotImplementedError.new 'TISCaP Error is abstract---please subclass and override #transmission'
    end
end


#
# A GeneralTiscapError is a TiscapError.
# Like other exceptions, it takes a string argument on its
# constructor, which it uses as its message. This message
# gets sent when it goes out to the client.
# 
class GeneralTiscapError < TiscapError
    def transmission
        TiscapTransmission.new :']error', self.message, nil
    end
end


#
# A BadSyntaxError is a TiscapError.
# It ignores its message, if given.
# 
class BadSyntaxError < TiscapError
    def transmission
        TiscapTransmission.new :']badsyntax', nil, nil
    end
end


#
# A UsernameTakenError is a TiscapError.
# It also ignores its message, if given.
# 
class UsernameTakenError < TiscapError
    def transmission
        TiscapTransmission.new :']usernametaken', nil, nil
    end
end
