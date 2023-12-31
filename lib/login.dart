
import 'dart:convert';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:field_app/routing/bottom_nav.dart';
import 'package:field_app/services/db.dart';
import 'package:field_app/widget/drop_down.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}
class _LoginState extends State<Login> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellow,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/logo/sk.png',
              ),
              LoginSignupPage()
            ],
          ),
        ),
      ),
    );
  }
}
class UserLogin extends StatefulWidget {
  @override
  _UserLoginState createState() => _UserLoginState();
}

class _UserLoginState extends State<UserLogin> {

  final _formKey = GlobalKey<FormState>();

  String _email ='';
  String _password ='';
  String _confirmPassword ='';
  String role ='';
  String zone ='';
  String region ='';
  String area ='';
  String country ='';
  String firstname ='';
  String lastname ='';
  bool isLoading = true;
  List? data = [];
  List<String> countrydata = [];
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      var connection = await Database.connect();
        final response = await http.post(
          Uri.parse('https://sun-kingfieldapp.herokuapp.com/api/auth/signin'), // Replace with your API endpoint URL.
          body: {
            'email': _email,
            'pass1': _password,
          },
        );
        SharedPreferences prefs = await SharedPreferences.getInstance();
        print(response.statusCode);
        if (response.statusCode== 200) {
          var results = await connection.query( "SELECT * FROM fieldappusers_feildappuser WHERE email = @email",
              substitutionValues: {"email":_email});
          var Row = results[0];
          prefs.setString('email', Row[4]);
          prefs.setString('name', Row[6] + ' ' + Row[7]);
          prefs.setString('country', Row[8]);
          prefs.setString('zone', Row[10]);
          prefs.setString('region', Row[9]);
          prefs.setString('area', Row[14]);
          prefs.setString('role', Row[11]);
          prefs.setString('email', _email);
          prefs.setBool('isLogin',true);
          print(prefs.get('name'));
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => NavPage()));
        }else{
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          String successMessage = responseData['error'];
          final snackBar = SnackBar(
            content: Text(successMessage),
            duration: Duration(seconds: 3),
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }


    }
  }

  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0,left: 10, right: 10),
      child:Column(children: [
        TextFormField(
          decoration: const InputDecoration(

              fillColor: Colors.white,
              filled: true,
              labelText: 'Email'),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            return null;
          },
          onChanged: (value) {
            _email = value;
          },
        ),
        SizedBox(height: 10,),
        TextFormField(
          decoration: InputDecoration(
              labelText: 'Password',
            fillColor: Colors.white,
            filled: true,),
          obscureText: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password';
            }
            return null;
          },
          onChanged: (value) {
            _password = value;
          },
        ),
      ],
      )
    );
  }
}
class LoginSignupPage extends StatefulWidget {
  @override
  _LoginSignupPageState createState() => _LoginSignupPageState();
}
enum AuthMode { Login, Signup }
class _LoginSignupPageState extends State<LoginSignupPage> {
  final _formKey = GlobalKey<FormState>();

  String _email ='';
  String _password ='';
  String _confirmPassword ='';
  String role ='';
  String zone ='';
  String region ='';
  String area ='';
  String country ='';
  String firstname ='';
  String lastname ='';
  bool isLoading = true;
  List? data = [];

  List<String> countrydata = [];
  List<String> zonedata = [];
  List<String> regiondata = [];
  List<String> areadata = [];
  AuthMode _authMode = AuthMode.Login;
  Future<StorageItem?> listItems(key) async {
    try {
      StorageListOperation<StorageListRequest, StorageListResult<StorageItem>>
      operation = await Amplify.Storage.list(
        options: const StorageListOptions(
          accessLevel: StorageAccessLevel.guest,
          pluginOptions: S3ListPluginOptions.listAll(),
        ),
      );

      Future<StorageListResult<StorageItem>> result = operation.result;
      List<StorageItem> resultList = (await operation.result).items;
      resultList = resultList.where((file) => file.key.contains(key)).toList();
      if (resultList.isNotEmpty) {
        // Sort the files by the last modified timestamp in descending order
        resultList.sort((a, b) => b.lastModified!.compareTo(a.lastModified!));
        StorageItem latestFile = resultList.first;

        CoutryData(latestFile.key);
        print(latestFile.key);
        return resultList.first;
      } else {
        print('No files found in the S3 bucket with key containing "$key".');
        return null;
      }
      safePrint('Got items: ${resultList.length}');
    } on StorageException catch (e) {
      safePrint('Error listing items: $e');
    }
  }
  Future<void> CoutryData(key) async {
    List<String> uniqueCountry = [];
    print("data Object: $key");


    try {
      StorageGetUrlResult urlResult = await Amplify.Storage.getUrl(
          key: key)
          .result;

      final response = await http.get(urlResult.url);
      final jsonData = jsonDecode(response.body);
      print('File_team: $jsonData');

      print(jsonData.length);

      for (var item in jsonData) {
        uniqueCountry.add(item['Country']);

      }
      setState(() {
        countrydata = uniqueCountry.toSet().toList();
        data = jsonData;
        isLoading = false;

      });
    } on StorageException catch (e) {
      safePrint('Could not retrieve properties: ${e.message}');
      rethrow;
    }
  }
  Future<void> Zone() async {
    List<String> uniqueZone = [];
    final jsonZone = data?.where((item) => item['Country'] == country).toList();
    for (var ZoneList in jsonZone!) {
      String Zone = ZoneList['Zone'];
      //region?.add(region);
      uniqueZone.add(Zone);
    }
    setState(() {

      zonedata = uniqueZone.toSet().toList();
      safePrint('File_team: $data');
    });
    //safePrint('Area: $area');
  }
  Future<void> Region() async {
    List<String> uniqueRegion= [];
    final jsonArea = data?.where((item) => item['Zone'] == zone && item['Country']== country).toList();
    for (var RegionList in jsonArea!) {
      String region = RegionList['Region'];
      //region?.add(region);
      uniqueRegion.add(region);
    }
    setState(() {

      regiondata = uniqueRegion.toSet().toList();
      safePrint('File_team: $regiondata');
    });
    //safePrint('Area: $area');
  }
  Future<void> Area() async {
    List<String> uniqueArea = [];
    final jsonArea = data?.where((item) => item['Region'] == region && item['Country']== country).toList();
    for (var areaList in jsonArea!) {
      String area = areaList['Current Area'];
      //region?.add(region);
      uniqueArea.add(area);
    }
    setState(() {

      areadata = uniqueArea.toSet().toList();
      safePrint('File_team: $areadata');
    });
    //safePrint('Area: $area');
  }
  Future<void> _submitForm() async {
    print(_authMode);
    if (_formKey.currentState!.validate()) {
      var connection = await Database.connect();
      if(_authMode == AuthMode.Login){
        final response = await http.post(
          Uri.parse('https://sun-kingfieldapp.herokuapp.com/api/auth/signin'), // Replace with your API endpoint URL.
          body: {
            'email': _email,
            'pass1': _password,
          },
        );
        SharedPreferences prefs = await SharedPreferences.getInstance();
        print(response.statusCode);
        if (response.statusCode== 200) {
          var results = await connection.query( "SELECT * FROM fieldappusers_feildappuser WHERE email = @email",
              substitutionValues: {"email":_email});
          var Row = results[0];
          prefs.setString('email', Row[4]);
          prefs.setString('name', Row[6] + ' ' + Row[7]);
          prefs.setString('country', Row[8]);
          prefs.setString('zone', Row[14]);
          prefs.setString('region', Row[9]);
          prefs.setString('area', Row[10]);
          prefs.setString('role', Row[11]);
          prefs.setString('email', _email);
          prefs.setBool('isLogin',true);
          print(prefs.get('name'));
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => NavPage()));
        }else{
          print(response.body);
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          String successMessage = responseData['error'];
          final snackBar = SnackBar(
            content: Text(successMessage),
            duration: Duration(seconds: 3),
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }
      }else {
        try{
          final response = await http.post(
            Uri.parse('https://sun-kingfieldapp.herokuapp.com/api/auth/signup'),
            body: {
              'username' : _email,
              'fname' :firstname ,
              'lname' : lastname,
              'email' : _email,
              'country' :country,
              'zone' : zone,
              'region' :region ,
              'area' : area,
              'role' : role,
              'pass1' : _password,
              'pass2' : _confirmPassword,

            },
          );
          if(response.statusCode == 201){
            final Map<String, dynamic> responseData = jsonDecode(response.body);
            String successMessage = responseData['message'];
            final snackBar = SnackBar(

              content: Text(successMessage),
              duration: Duration(seconds: 3),
            );
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
            setState(() {
              _authMode = AuthMode.Login;
            });
          }else{
            print(response.body);
            final Map<String, dynamic> responseData = jsonDecode(response.body);
            String successMessage = responseData['error'];
            final snackBar = SnackBar(
              content: Text(successMessage),
              duration: Duration(seconds: 3),
            );
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
            print(successMessage);
          }
        }catch (e) {
          print('Error executing query: $e');
        } finally {
          await connection.close();
        }
      }
    }
  }
  @override
  void initState()  {

    // TODO: implement initState
    super.initState();
    listItems("country");


  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellow,
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.fromLTRB(10,100.0,10,0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/logo/sk.png',
                ),
                if(_authMode == AuthMode.Signup)
                  Column(children: [
                    TextFormField(
                      decoration: InputDecoration(labelText: 'First Name',
                        fillColor: Colors.white,
                        filled: true,),
                      style: TextStyle(color: Colors.black),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your First Name';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        firstname = value;
                      },
                    ),
                    SizedBox(height: 10,),
                    TextFormField(
                      style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(labelText: 'Last Name',
                        fillColor: Colors.white,

                        filled: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your Last Name';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        lastname = value;
                      },
                    ),
                    SizedBox(height: 10,),
                    AppDropDown(
                        disable: false,
                        label: "Country",
                        hint: "Country",
                        items: countrydata,
                        validator: (value){
                          if (value == null || value.isEmpty) {
                            return 'Please enter your Country';
                          }
                          return null;
                        },
                        onChanged: (value){
                          country = value;
                          setState(() {
                            zone = "";
                          });
                          Zone();
                        }),
                    SizedBox(height: 10,),
                    AppDropDown(
                        disable: false,
                        label: "Zone",
                        hint: "Zone",
                        items: zonedata,
                        validator: (value){
                          if (value == null || value.isEmpty) {
                            return 'Please enter your Zone';
                          }
                          return null;
                        },
                        onChanged: (value){
                          zone = value;
                          regiondata=[];
                          Region();
                        }),
                    SizedBox(height: 10,),

                    AppDropDown(
                        disable: false,
                        label: "Region",
                        hint: "Region",
                        items: regiondata,
                        validator: (value){
                          if (value == null || value.isEmpty) {
                            return 'Please enter your Zone';
                          }
                          return null;
                        },
                        onChanged: (value){
                          region = value;
                          Area();
                        }),
                    SizedBox(height: 10,),
                    AppDropDown(
                        disable: false,
                        label: "Area",
                        hint: "Area",
                        items: areadata,
                        validator: (value){
                          if (value == null || value.isEmpty) {
                            return 'Please enter your Area';
                          }
                          return null;
                        },
                        onChanged: (value){
                          area = value;
                        }),
                    SizedBox(height: 10,),
                    AppDropDown(
                        disable: false,
                        label: "Role",
                        hint: "Role",
                        items: const ["Area Collection Executive"],
                        validator: (value){
                          if (value == null || value.isEmpty) {
                            return 'Please enter your Role';
                          }
                          return null;
                        },
                        onChanged: (value){
                          role = value;
                        }),

                  ],),
                SizedBox(height: 10,),
                TextFormField(
                  style: TextStyle(color: Colors.black),
                  decoration: const InputDecoration(labelText: 'Email',
                    fillColor: Colors.white,
                    filled: true,
                  ),
                  validator: (value) {

                    var domain  = value!.split('@');
                    print(domain);
                    print(domain[1]);
                    if (value == null || value.isEmpty || domain![1].toLowerCase() !='sunking.com') {
                      return 'Please enter avalid email';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    _email = value;
                  },
                ),
                SizedBox(height: 10,),
                TextFormField(
                  style: TextStyle(color: Colors.black),
                  decoration: InputDecoration(labelText: 'Password',
                    fillColor: Colors.white,
                    filled: true,
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    _password = value;
                  },
                ),
                SizedBox(height: 10,),
                if (_authMode == AuthMode.Signup)

                  TextFormField(
                    style: TextStyle(color: Colors.black),
                    decoration: InputDecoration(labelText: 'Confirm Password',
                      fillColor: Colors.white,
                      filled: true,
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter confirm password';
                      } else if (value != _password) {
                        return 'Password does not match';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _confirmPassword = value;
                      });
                    },
                  ),
                SizedBox(height: 20.0),
                ElevatedButton(
                  child: Text(_authMode == AuthMode.Login ? 'Login' : 'Sign Up'),
                  onPressed: _submitForm,
                ),
                TextButton(
                  child: Text(_authMode == AuthMode.Login ? 'Create Account' : 'Back to Login',
                    style:
                    TextStyle(color: Colors.white,
                      fontSize: 20.0
                    ),),
                  onPressed: () {
                    setState(() {
                      _authMode = _authMode == AuthMode.Login ? AuthMode.Signup : AuthMode.Login;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

