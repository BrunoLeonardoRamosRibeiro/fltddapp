import 'package:faker/faker.dart';
import 'package:fltddapp/data/http/http.dart';
import 'package:fltddapp/data/usecases/usecases.dart';
import 'package:fltddapp/domain/helpers/helpers.dart';
import 'package:fltddapp/domain/usecases/authentication.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

class HttpClientSpy extends Mock implements HttpClient {}

void main() {
  RemoteAuthentication sut;
  HttpClientSpy httpClient;
  String url;
  AuthenticationParams params;

  setUp(() {
    httpClient = HttpClientSpy();
    url = faker.internet.httpUrl();
    sut = RemoteAuthentication(httpClient: httpClient, url: url);
    params = AuthenticationParams(email: faker.internet.email(), secret: faker.internet.password());
  });

  test('Should call HttpClient with correct Values', () async {
    when(httpClient.request(url: anyNamed('url'), method: anyNamed('method'), body: anyNamed('body')))
        .thenAnswer((realInvocation) async => {'accessToken': faker.guid.guid(), 'name': faker.person.name()});

    await sut.auth(params);

    verify(
      httpClient.request(
        url: url,
        method: 'post',
        body: {"email": params.email, "password": params.secret},
      ),
    );
  });

  test('Should throw UnexpectedError if HttpClient return 400', () async {
    when(httpClient.request(url: anyNamed('url'), method: anyNamed('method'), body: anyNamed('body')))
        .thenThrow(HttpError.badRequest);

    final future =  sut.auth(params);

    expect(future, throwsA(DomainError.unexpected));
  });

  test('Should throw UnexpectedError if HttpClient return 404', () async {
    when(httpClient.request(url: anyNamed('url'), method: anyNamed('method'), body: anyNamed('body')))
        .thenThrow(HttpError.notFound);

    final future =  sut.auth(params);

    expect(future, throwsA(DomainError.unexpected));
  });

  test('Should throw UnexpectedError if HttpClient return 500', () async {
    when(httpClient.request(url: anyNamed('url'), method: anyNamed('method'), body: anyNamed('body')))
        .thenThrow(HttpError.serverError);

    final future =  sut.auth(params);

    expect(future, throwsA(DomainError.unexpected));
  });

  test('Should throw UnexpectedError if HttpClient return 401', () async {
    when(httpClient.request(url: anyNamed('url'), method: anyNamed('method'), body: anyNamed('body')))
        .thenThrow(HttpError.unauthorized);

    final future =  sut.auth(params);

    expect(future, throwsA(DomainError.invalidCredentials));
  });

  test('Should return an Account if HttpClient returns 200', () async {
    final accessToken = faker.guid.guid();
    when(httpClient.request(url: anyNamed('url'), method: anyNamed('method'), body: anyNamed('body')))
        .thenAnswer((_) async => {'accessToken': accessToken, 'name': faker.person.name()});

    final account =  await sut.auth(params);

    expect(account.token, accessToken);
  });

  test('Should throw UnexpectedError if HttpClient returns 200 with invalid data', () async {

    when(httpClient.request(url: anyNamed('url'), method: anyNamed('method'), body: anyNamed('body')))
        .thenAnswer((_) async => {'invalid_key': 'invalid_value'});

    final future = await sut.auth(params);

    print('Erro => ${future.toString()}');

    expect(future, throwsA(DomainError.unexpected));
  });


}
