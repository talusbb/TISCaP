# encoding: utf-8

#
# Jimports: Java Imports!
# 
# This file provides a handful of native Ruby modules,
# each encapsulating the entire namespace of a Java package.
# This allows native-syntax reference to Java classes;
# for instance, “JavaConcurrent::Executors”
# corresponding to “java.util.concurrent.Executors”
# 
# This file is required by whatever files need easy access
# to the Java libraries.
# 


require 'java'

module JavaLang
    include_package 'java.lang'
    
    # The ‘include_package’ directive snags the entire package
    # namespace into the local namespace, similar to
    # Java's ‘import java.util.*’, for instance.
    # But we do so in the namespace of a module, to reduce
    # the risk of conflicts.
    
end

module JavaUtil
    include_package 'java.util'
end

module JavaConcurrent
    include_package 'java.util.concurrent'
end
