import 'package:app_links/app_links.dart';

abstract interface class OAuthRedirectSource {
  Stream<Uri> get links;
}

class AppLinksOAuthRedirectSource implements OAuthRedirectSource {
  AppLinksOAuthRedirectSource({AppLinks? appLinks})
      : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;

  @override
  Stream<Uri> get links => _appLinks.uriLinkStream;
}
