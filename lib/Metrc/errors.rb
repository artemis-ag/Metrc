module Metrc
  module Errors
    class MissingConfiguration < RuntimeError; end
    class MissingParameter < RuntimeError; end
    class RequestError < RuntimeError; end

    class BadRequest < RequestError; end
    class Unauthorized < RequestError; end
    class Forbidden < RequestError; end
    class NotFound < RequestError; end
    class TooManyRequests < RequestError; end
    class InternalServerError < RequestError; end
  end
end
