# File appender
#
#   Writes log messages to a file or open iostream
#
module SemanticLogger
  module Appender
    class File < SemanticLogger::Appender::Base

      # Create a File Logger appender instance
      #
      # Example
      #    require 'semantic_logger'
      #
      #    # Enable trace level logging
      #    SemanticLogger.default_level = :info
      #
      #    # Log to screen
      #    SemanticLogger.add_appender(STDOUT)
      #
      #    # And log to a file at the same time
      #    SemanticLogger::Logger.add_appender('application.log')
      #
      #    logger = SemanticLogger['test']
      #    logger.info 'Hello World'
      #
      # Example 2. To log all levels to file and only :info and above to screen:
      #
      #    require 'semantic_logger'
      #
      #    # Enable trace level logging
      #    SemanticLogger.default_level = :trace
      #
      #    # Log to screen but only display :info and above
      #    SemanticLogger.add_appender(STDOUT, :info)
      #
      #    # And log to a file at the same time, including all :trace level data
      #    SemanticLogger.add_appender('application.log')
      #
      #    logger =  SemanticLogger['test']
      #    logger.info 'Hello World'
      #
      def initialize(filename, level=nil, filter=nil, &block)
        raise 'filename cannot be null when initializing the SemanticLogging::Appender::File' unless filename
        @log =
          if filename.respond_to?(:write) and filename.respond_to?(:close)
            filename
          else
            @filename = filename
            reopen
          end

        # Set the log level and formatter if supplied
        super(level, filter, &block)
      end

      # After forking an active process call #reopen to re-open
      # open the file handles etc to resources
      #
      # Note: This method will only work if a String filename was supplied
      #       on the initializer.
      def reopen
        return unless @filename

        @log      = open(@filename, (::File::WRONLY | ::File::APPEND | ::File::CREAT))
        # Force all log entries to write immediately without buffering
        # Allows multiple processes to write to the same log file simultaneously
        @log.sync = true
        @log.set_encoding(Encoding::BINARY) if @log.respond_to?(:set_encoding)
        @log
      end

      # Pass log calls to the underlying Rails, log4j or Ruby logger
      #  trace entries are mapped to debug since :trace is not supported by the
      #  Ruby or Rails Loggers
      def log(log)
        # Ensure minimum log level is met, and check filter
        return false if (level_index > (log.level_index || 0)) || !include_message?(log)

        # Since only one appender thread will be writing to the file at a time
        # it is not necessary to protect access to the file with a semaphore
        # Allow this logger to filter out log levels lower than it's own
        @log.write(@formatter.call(log) << "\n")
        true
      end

      # Flush all pending logs to disk.
      #  Waits for all sent documents to be writted to disk
      def flush
        @log.flush if @log.respond_to?(:flush)
      end

    end
  end
end
