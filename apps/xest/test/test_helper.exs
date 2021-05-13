ExUnit.start()

Hammox.defmock(DateTimeMock, for: Xest.DateTime.Behaviour)
Hammox.defmock(TestServerMock, for: Xest.APIServer)

Application.put_env(:xest, :date_time_module, DateTimeMock)
Application.put_env(:xest, :api_test_server, TestServerMock)
