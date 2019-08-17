ExUnit.start()

Mox.defmock(MockJSONCodec, for: JSONCodec)
Mox.defmock(RubberBand.Client.Drivers.Mock, for: RubberBand.Client.Driver)
