ExUnit.start()

Mox.defmock(MockJSONCodec, for: JSONCodec)
Mox.defmock(RubberBand.Adapters.AdapterWithDefaults, for: RubberBand.Adapter)
Mox.defmock(RubberBand.Adapters.AdapterWithoutDefaults, for: RubberBand.Adapter)
