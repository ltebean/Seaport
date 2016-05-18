##Introduction
Seaport makes it easy to ship static resources to ios client. You just need to add a few lines of code, Seaport will handle all the rest things, including:

* download package
* manage versions
* syncronize local package
* remove unused package



##Getting Started

#### 1. Set up the server
You can find the instruction here: https://github.com/ltebean/seaport-server

####2. Install seaport-client

You can use seaport-client to publish packages. It's written in Node.js, you can install it by:

```
npm install -g seaport-client
```


####3. Publish a Package

Run `seaport publish`, specify the package name and version, the current working directory will be packed into a zip and published to the package cloud:

```
seaport publish -p index -v 1.0.0
```


####4. Intergrate Seaport in Your App
On ios side, first init a Seaport client by specifying the server address and app secret

```objective-c
NSArray *packageRequirements = @[
    @{@"name": @"package1", @"versionRange": @">1.0.0"}
];
    
self.seaport = [[Seaport alloc] initWithAppName:@"TestApp"
                                         secret:@"secret"
                                  serverAddress:@"http://localhost:8080"
                            packageRequirements:packageRequirements];
```

Check whether there are some updates, usually it should be called when app starts:

```objective-c
[seaport checkUpdate];
```

Then you could ask Seaport where is your package's root path, thus you can load static resources from that path:

```objective-c
NSString *rootPath = [seaport packagePath:@"index"];
if (rootPath) {
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
- (void)seaport:(Seaport *)seaport didStartDownloadPackage:(NSString *)packageName version:(NSString *)version;
  
- (void)seaport:(Seaport *)seaport didFinishDownloadPackage:(NSString *)packageName version:(NSString *)version;
  
- (void)seaport:(Seaport *)seaport didFailDownloadPackage:(NSString *)packageName version:(NSString *)version withError:(NSError *)error;
  
- (void)seaport:(Seaport *)seaport didFinishUpdatePackage:(NSString *)packageName version:(NSString *)version;  
```
