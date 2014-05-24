##Introduction
Seaport makes it easy to ship static resources to ios client. You just need to add a few lines of code, Seaport will handle all the rest things, including:

* download package
* manager versions
* syncronize local package
* remove unused package



##Getting Started

####Install CouchDB
Seaport uses couchdb as its backend, so you must install couchdb first. 

After finished, you should create a database called "seaport" and import all the views by replication from "http://couch.seaport.io/seaport"

####Intergrate Seaport in Your App
First init a Seaport client by specifing the appName and couchdb address:

	Seaport *seaport = [[Seaport alloc]initWithAppKey:@"test" serverAddress:@"192.168.9.49:5984"];
	
Check whether there are some updates, usually it should be called when app starts:

	[seaport checkUpdate];
	
Then you could ask Seaport where is your package's root path:

	NSString *rootPath = [seaport packagePath:@"index"];
	
If you are interested in the life cycle of package management, you could implement Seaport protocal and set the delegate to self:

	seaport.delegate = self;


Seaport protocal:

	-(void)seaport:(Seaport*)seaport didStartDownloadPackage:(NSString*) packageName version:(NSString*) version;
	
	-(void)seaport:(Seaport*)seaport didFinishDownloadPackage:(NSString*) packageName version:(NSString*) version;
	
	-(void)seaport:(Seaport*)seaport didFailDownloadPackage:(NSString*) packageName version:(NSString*) version withError:(NSError*) error;
	
	-(void)seaport:(Seaport*)seaport didFinishUpdatePackage:(NSString*) packageName version:(NSString*) version;	


####Deliver a new package

When you need to deliver a new package to app, All the operation is made on couchdb side;

* First upload the zip file as attachment in the package doc, the name of  the zip file is by convention "packageName-version".
* Then change the activeVersion to the version you want.

