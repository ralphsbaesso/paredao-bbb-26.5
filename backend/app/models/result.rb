class Result
  attr_reader :data, :status, :errors, :meta, :result_code
  def initialize(**args)
    @data = args[:data] if args.key?(:data)
    @status = args[:status] if args.key?(:status)
    @errors = args[:errors] if args.key?(:errors)
    @meta = args[:meta] if args.key?(:meta)
    @result_code = args[:result_code] if args.key?(:result_code)
  end
end
