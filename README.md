##Introduction
Seaport makes it easy to ship static resources to ios client. You just need to add a few lines of code, Seaport will handle all the rest things, including:

* download package
* manage versions
* syncronize local package
* remove unused package



##Getting Started

####1. Install CouchDB
Seaport uses couchdb as its backend, so you must install couchdb first. 

After finished, create a database and import all the views and examples by replicating from "http://223.4.15.141:9984/seaport"

####2. Intergrate Seaport in Your App
First init a Seaport client by specifing the appName, couchdb address, and  database name:

```oc
Seaport *seaport = [[Seaport alloc]initWithAppName:@"TestApp"
                                      	serverHost:@"223.4.15.141"
                                      	sevrerPort:@"9984"
                                          	dbName:@"seaport"];
```

Check whether there are some updates, usually it should be called when app starts:

```oc
[seaport checkUpdate];
```

Then you could ask Seaport where is your package's root path, then load static resources from that path:

```oc
NSString *rootPath = [seaport packagePath:@"helloworld"];
if(rootPath){
    NSString *filePath = [rootPath stringByAppendingPathComponent:@"index.html"];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:filePath]];
    [self.webView loadRequest:request];
}
```
	
If you are interested in the life cycle of package management, you could implement Seaport protocal and set the delegate to self:

```oc
seaport.delegate = self;
```

Seaport protocal:

```
-(void)seaport:(Seaport*)seaport didStartDownloadPackage:(NSString*) packageName version:(NSString*) version;
	
-(void)seaport:(Seaport*)seaport didFinishDownloadPackage:(NSString*) packageName version:(NSString*) version;
	
-(void)seaport:(Seaport*)seaport didFailDownloadPackage:(NSString*) packageName version:(NSString*) version withError:(NSError*) error;
	
-(void)seaport:(Seaport*)seaport didFinishUpdatePackage:(NSString*) packageName version:(NSString*) version;	
```

####3. Deliver a new package

When you need to deliver a new package to app, All the operation is made on couchdb side.

* First upload the zip file as attachment in the package doc, the name of  the zip file is by convention "packageName-version".
* Then change the activeVersion to the version you want.
* When the next time [seaport checkupdate] gets called, the new package will be delivered to the app.

Alternatively, you could use [seaport client tool](https://www.npmjs.org/package/seaport-client) to do all the jobs. 