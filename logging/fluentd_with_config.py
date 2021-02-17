import logging.config
import logging
import yaml

with open('logging/logging.yml') as fd:
    conf = yaml.load(fd, Loader=yaml.FullLoader)

logging.config.dictConfig(conf['logging'])

log = logging.getLogger(__name__)
log.debug("This is a debug message")
log.info("This is a info message")
log.error("This is a error message")