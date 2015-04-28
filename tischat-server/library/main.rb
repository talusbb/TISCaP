# encoding: utf-8
# ⎛The compiler does read the ^^first-line^^ comment⎞
# ⎝to determine the file encoding.                  ⎠



# Let's start at the very beginning
# (a very good place to start).



# Establish the only application-global constant,
# because it's so important:

TOTE = Encoding::UTF_8  # that is, The Only Text Encoding.



# And then we can kick-start the rest of the application.
# The ClientAcceptor initializer starts up the TCP server,
# and its #listen method creates the relevant objects to
# handle each client connection.
# 
# Really, the whole process is started in the ‘require_relative’
# line, where the tree of requires is started, classes are
# loaded, and singletons are set up.

require_relative 'ClientAcceptor'
ClientAcceptor.new.listen
