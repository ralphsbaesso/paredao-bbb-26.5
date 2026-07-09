class Result
attr_reader :data, :status, :errors, :meta
  def initialize(**args)
    @data = args[:data] if args.key?(:data)
    @status = args[:status] if args.key?(:status)
    @errors = args[:errors] if args.key?(:errors)
    @meta = args[:meta] if args.key?(:meta)
  end
end
