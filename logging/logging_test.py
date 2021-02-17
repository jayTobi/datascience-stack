import logging
import logging.config

logging.config.fileConfig("logging/logging.ini", disable_existing_loggers=False)

log = logging.getLogger("loggingTest")

log.debug("This is a debug message")
log.info("This is an info message")
log.error("This is an error message")