# SynWebBroker

SynWebBroker integrates Delphi's WebBroker technologies into Synopse mORMot
framework. Primary developped to use web- / soap-modules within mORMot, it's
also possible now to create HTTP API based webservices using the fast http.sys
on Windows plattforms instead of the existing webserver interfaces namely
CGI or ISAPI or of course the Indy WebBroker Bridge.

To enable WebBroker support in your mORMot based applications simply use an
instance of the `TSQLWebBrokerServer` class instead of `TSQLHttpServer`.

For the usage of your WebBroker application together with Microsoft's fast
HTTP API simply create a `TSynHttpApiWebBrokerServer` and register your
webmodules by a call to `AuthorizeWebModules`.

Easy integration in a `TServiceApplication` can be done by inheriting a
service from `TSQLWebBrokerService` and override the function
`CreateServerInstance`. A design time package must be installed to register
the new service class at the IDE (see Installation).


Currently tested with Delphi XE3, but should work from Delphi 6 up to Delphi 10.3 Rio


## Installation

* Use Git or checkout with SVN using the web URL: https://github.com/gilbertsoft/delphi-SynWebBroker.git
* Add the source directory to the IDE's or a project's search path
* Compile and install packages\mORMotDesign.dpk if you like to use the TSQLWebBrokerService class
