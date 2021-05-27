ExUnit.start()

Hammox.defmock(TestServerMock, for: Xest.APIServer)

Application.put_env(:xest, :api_test_server, TestServerMock)
