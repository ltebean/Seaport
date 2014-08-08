##Introduction
Seaport makes it easy to ship static resources to ios client. You just need to add a few lines of code, Seaport will handle all the rest things, including:

* download package
* manage versions
* syncronize local package
* remove unused package



##Getting Started

Seaport provides a default [package cloud](http://223.4.15.141:9984/seaport), and with [seaport-client](https://www.npmjs.org/package/seaport-client) you can easily manage your packages.

####1. Install seaport-client

Node.js environment is required, then install seaport-client by:

```
npm install -g seaport-client
```

####2. Register an Account

Run `seaport adduser`, specify your username and password:

```
seaport adduser -u ltebean -s test
```

####3. Publish a Package

Run `seaport publish`, specify the appName, packageName, and current version, the current working directory will be packed into a zip and published to the package cloud:

```
seaport publish -a TestApp -p index -v 1.0.0
```

####4. Activate a specific version

For example, activate version 1.1.0 of package 'index' with appName 'TestApp':
```
seaport activate -a TestApp -p index -v 1.1.0

```


####5. Intergrate Seaport in Your App
On ios side, first init a Seaport client by specifing the appName, package cloud address, and database name:

```objective-c
Seaport *seaport = [[Seaport alloc]initWithAppName:@"TestApp"
                                        serverHost:@"223.4.15.141"
                                        sevrerPort:@"9984"
                                            dbName:@"seaport"];
```

Check whether there are some updates, usually it should be called when app starts:

```objective-c
[seaport checkUpdate];
```

Then you could ask Seaport where is your package's root path, then load static resources from that path:

```objective-c
NSString *rootPath = [seaport packagePath:@"index"];
if(rootPath){
    NSString *filePath = [rootPath stringByAppendingPathComponent:@"index.html"];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:filePath]];
    [self.webView loadRequest:request];
}
```
  
If you are interested in the life cycle of package management, you could implement Seaport protocal:

```objective-c
seaport.delegate = self;
```

Seaport protocal:

```objective-c
-(void)seaport:(Seaport*)seaport didStartDownloadPackage:(NSString*) packageName version:(NSString*) version;
  
-(void)seaport:(Seaport*)seaport didFinishDownloadPackage:(NSString*) packageName version:(NSString*) version;
  
-(void)seaport:(Seaport*)seaport didFailDownloadPackage:(NSString*) packageName version:(NSString*) version withError:(NSError*) error;
  
-(void)seaport:(Seaport*)seaport didFinishUpdatePackage:(NSString*) packageName version:(NSString*) version;  
```

## Setup your own package cloud

Seaport uses couchdb as its backend, so you must install couchdb first. 

After finished, create a database and import all the views and examples by replicating from "http://223.4.15.141:9984/seaport"

Finally change the host, port, dbname config to the correspoding value in your code.