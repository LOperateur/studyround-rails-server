ActiveModelSerializers.config.adapter = :json

# Exclude ams logging
ActiveModelSerializers.logger = Logger.new(IO::NULL)