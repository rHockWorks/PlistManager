/**
 MIT License
 
 Copyright (c) 2017 Alex Nagy
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

import Foundation





enum PlistManagerError: Error {
    case plistNotWritten
    case plistDoesNotExist
    case plistAvailable
    case plistUnavailable
    case plistAlreadyEmpty
    case keyValuePairExists
    case keyValuePairAlreadyExists
    case keyValuePairDoesNotExist
}




struct Plist {
  
  let plistName: String
  
  var plistPath: String? {
    guard let path = Bundle.main.path(forResource: plistName, ofType: "plist") else { return .none }
    return path
  }
  
  var destinationPath: String? {
    guard plistPath != .none else { return .none }
    let dir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]                     //DOCUMENTS FOLDER ON iDEVICE
    return (dir as NSString).appendingPathComponent("\(plistName).plist")
  }
  
  init?(plistName:String) {
    
    self.plistName = plistName
    
    let fileManager = FileManager.default
    
    guard let source = plistPath else {
      plistManagerPrint(">> cannot copy file into the 'Documents' folder because \(plistName).plist does not exist and therefore could not be initialised")
      return nil }
    guard let destination = destinationPath else { return nil }
    guard fileManager.fileExists(atPath: source) else {
      plistManagerPrint("the \(plistName).plist already exist")
      return nil }
    
    if !fileManager.fileExists(atPath: destination) {
      
      do {
        try fileManager.copyItem(atPath: source, toPath: destination)
      } catch let error as NSError {
        plistManagerPrint("cannot copy file: \(error.localizedDescription)")
        return nil
      }
    }
  }
  
    
      //CHECK IF VALUE EXISTS IN PERSISTENT PLIST AND RETURNS DATA
      func getValuesFromPersistentPlistFile() throws -> NSDictionary? {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: destinationPath!) {
          guard let dict = NSDictionary(contentsOfFile: destinationPath!) else { return .none }
          return dict
        } else {
          throw PlistManagerError.plistDoesNotExist
        }
      }
  
    
    
        //CREATES A DICTIONARY FROM THE ORIGINAL PLIST TO BE USED FOR PERSISTENT SAVED VALUES IN DOCUMENTS FOLDER ON iDEVICE
        func createMutablePlist() -> NSMutableDictionary? {
          let fileManager = FileManager.default
          if fileManager.fileExists(atPath: destinationPath!) {
              guard let dict = NSMutableDictionary(contentsOfFile: destinationPath!) else { return .none }
              return dict
          } else {
              return .none
          }
        }
  
    
    
          //ADD VALUE TO PERSISTENT PLIST
          func addValuesToPersistentPlist(dictionary: NSDictionary) throws {
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: destinationPath!) {
              if !dictionary.write(toFile: destinationPath!, atomically: false) {
                plistManagerPrint("error : plist cannot be written to !")
                throw PlistManagerError.plistNotWritten
              }
            } else {
              plistManagerPrint("error : plist does not exist on iDevice !")
              throw PlistManagerError.plistDoesNotExist
            }
          }
        }




    class SwiftyPlistManager {
  
        static let shared = SwiftyPlistManager()
        private init() {}                                                   //THIS PREVENTS OTHERS FROM USING THE DEFAULT "()" INITIALIZER FOR THIS CLASS
  
        var logPlistManager: Bool = false
  
        
        //ADD PLIST(S) TO BE INITIALISED
        func start(plistNames: [String], logging: Bool) {
    
            logPlistManager = logging
            
            plistManagerPrint(">>> starting PlistManager <<<")
            
            var itemCount = 0
            
            for plistName in plistNames {
              itemCount += 1
              if let _ = Plist(plistName: plistName) {
                plistManagerPrint("\(plistName).plist initialised")
              }
            }
            
            if itemCount == plistNames.count {                                              //CHECK ALL PLISTS IN ARRAY HAVE CYCLED
                if itemCount > 1 {
                    plistManagerPrint("finished initialising \(itemCount) plists")
                } else {
                    plistManagerPrint("plist finished initialising")
                }
            }
        }
  
    
        
  
        //ADD NEW VALUE TO PERSISTENT DATA PLIST
        func addNew(_ value: Any, forKey: String, toPlistWithName plistFile: String, completion: (_ error: PlistManagerError?) -> ()) {
        
            plistManagerPrint(">>> attempting to add '\(value)' for '\(forKey)' to \(plistFile).plist <<<")
            
            if checkKeyAlreadyExists(key: forKey, inPlistWithName: plistFile) == false {                //ONLY WRITE IF KEY DOESN'T EXIST
            
              createDictionary(fromPlistWithName: plistFile) { (result, err) in
              guard let dict = result else { return }
            
                    dict[forKey] = value
                    
                        addValueToPersistentPlist(withData: dict, forPlist: plistFile) { (error) in     //POST DICTIONARY CHECKS : THIS IS WHERE DATA IS SAVED INTO PERSISTENT PLIST
                        if error == nil {
                        }
                    }
                }
            } else {
                plistManagerPrint("\(forKey) already exists, not overwritten.")
                completion(.keyValuePairAlreadyExists)
            }
        }
  
    
        
    
        //REMOVE SPECIFIC PERSISTENT PLIST ENTRY
        func removeKeyValuePairs(for key: String, fromPlistWithName plistFile: String, completion: (_ error: PlistManagerError?) -> ()) {
          
          plistManagerPrint(">>> attempting to remove '\(key)' entry from \(plistFile).plist <<<")
          
          if checkKeyAlreadyExists(key: key, inPlistWithName: plistFile) == true {

              createDictionary(fromPlistWithName: plistFile) { (result, err) in
              guard let dict = result else { return }

              dict.removeObject(forKey: key)
              
                        addValueToPersistentPlist(withData: dict, forPlist: plistFile) { (error) in
                        if error == nil {
                        }
                    }
                }
            } else {
                plistManagerPrint("Nothing to purge, '\(key)' does not exist inside \(plistFile).plist")
                completion(.keyValuePairDoesNotExist)
                }
          }
  
        
  
        
        //PURGE ALL PERSISTENT PLIST ENTRIES
        func purgeAllKeyValuePairs(fromPlistWithName plistFile: String, completion: (_ error: PlistManagerError?) -> ()) {
            
            plistManagerPrint(">>> attempting to purge all values from \(plistFile).plist <<<")
          
            createDictionary(fromPlistWithName: plistFile) { (result, err) in
                guard let dict = result else { return }

                let keys = Array(dict.allKeys)
            
                if keys.count != 0 {
                    dict.removeAllObjects()
                } else {
                    plistManagerPrint("\(plistFile).plist is already empty !")
                    completion(.plistAlreadyEmpty)
                    return
                }
            
                    addValueToPersistentPlist(withData: dict, forPlist: plistFile) { (error) in
                        if error == nil {
                    }
                }
            }
            plistManagerPrint("cannot find: \(plistFile).plist")
            completion(.plistUnavailable)
        }
        
        
        
        
        
        
//        //UPDATE VALUE IN PERSISTENT PLIST (IF ENTRY EXISTS)
//        func save(_ value: Any, forKey: String, toPlistWithName plistFile: String, completion: (_ error: PlistManagerError?) -> ()) {
//
//          if checkKeyAlreadyExists(key: forKey, inPlistWithName: plistFile) == true {
//
//            createDictionary(fromPlistWithName: plistFile) { (result, err) in
//            guard let dict = result else { return }
//
//                if let dictValue = dict[forKey] {
//
//                  if type(of: value) != type(of: dictValue) {                                   //FIXME: MANAGE THIS ISSUE BETTER (type: "__NSCFString")
//                    plistManagerPrint("saving type \(type(of: value)) to \(type(of: dictValue)) mismatch, this could crash when read!")
//                  }
//                    plistManagerPrint("saved type \(type(of: value)) to \(plistFile).plist")
//                    dict[forKey] = value
//                }
//                    addValueToPersistentPlist(withData: dict, forPlist: plistFile) { (error) in     //POST DICTIONARY CHECKS : THIS IS WHERE DATA IS SAVED INTO PERSISTENT PLIST
//                        if error == nil {
//                        }
//                    }
//                }
//          } else if checkKeyAlreadyExists(key: forKey, inPlistWithName: plistFile) == false {   //FIXME: SAVE FIRST !!
//            print("\(forKey) cannot be saved before having been added!")
//            }
//        }
        
        
        
        
    
        
        
        //CHECK FOR SPECIFIC VALUE IN PERSISTENT PLIST
        func checkValue(for key: String, fromPlistWithName plistFile: String, completion: (_ result: Any?, _ error: PlistManagerError?) -> ()) {
    
            plistManagerPrint(">>> checking if '\(key)' exist inside \(plistFile).plist <<<")
            
            var value: Any?

            createDictionary(fromPlistWithName: plistFile) { (result, err) in
                guard let dict = result else { return }                                                                     //TRY TO CREATE A DICTIONARY FROM PLIST DATA

            let dictKeys = Array(dict.allKeys)                                                                              //GET ALL KEYS IN PERSISTENT PLIST (DICTIONARY)
          
            let dictKeyFound: String = checkDictionaryKeyExists(forKey: key, inPlist: dictKeys, withPlistName: plistFile)   //CHECK IF KEY EXISTS IN PERSISTENT PLIST
          
            value = dict[dictKeyFound]! as Any                                                                              //ASSIGN PERSISTENT PLIST VALUE

                if value != nil {
                    plistManagerPrint("Sending value to completion handler: \(value ?? "Default Value" as Any)")
                    completion(value, .keyValuePairExists)
                } else {
                    plistManagerPrint("'\(key)' does not exist in \(plistFile).plist")
                    completion(nil, .keyValuePairDoesNotExist)
                }
            }
        }

        
        
        
    
            //LOGIC GATE : CHECK IF KEY IN PERSISTENT PLIST EXISTS
            func checkKeyAlreadyExists(key: String, inPlistWithName plistFile: String) -> Bool {
        
                var keyExists = false
        
                createDictionary(fromPlistWithName: plistFile) { (result, err) in
                guard let dict = result else { return }
                  
                    let dictKeys = Array(dict.allKeys)
                   
                    if checkDictionaryKeyExists(forKey: key, inPlist: dictKeys, withPlistName: plistFile) != "" {
                        plistManagerPrint("'\(key)' exists in \(plistFile).plist!")
                        keyExists = true
                        return
                    } else if checkDictionaryKeyExists(forKey: key, inPlist: dictKeys, withPlistName: plistFile) == "" {
                        keyExists = false
                        return
                    }
                }
                return keyExists
              }
        
        
        
        
        
        
        //REQUEST ALL VALUES FROM PERSISTENT PLIST (ON DEMAND)
        func revealFullPersistenPlistContents(withPlistName plistFile: String) {
            
            plistManagerPrint(">>> reveal all values contained in \(plistFile).plist <<<")
            
            if let plist = Plist(plistName: plistFile) {
              
                logAction(forPlist: plist, withPlistName: plistFile)
                //FIXME: IF DICTIONARY/PLIST IS EMPTY IT WILL NOT PRINT ANYTHING, THERE IS NO FEEDBACK FOR THIS EVENT
            }
        }
        
        
  
        
        
            //PRINT OUT ALL PERSISTENT PLIST VALUES (AFTER FUNCTION ACTION)
            func logAction(forPlist plist: Plist, withPlistName: String) {
        
                if logPlistManager == true {
          
                    plistManagerPrint("checking for changes in \(withPlistName).plist")
          
                  do {
                    let plistValues = try plist.getValuesFromPersistentPlistFile()              //CHECKING FOR *.VALUES IN PERSISTENT PLIST
                    plistManagerPrint("\(plistValues ?? [:])")
                    return
                  } catch {
                    plistManagerPrint("no values in \(withPlistName).plist")
                    plistManagerPrint(error)
                  }
                }
              }
  
        
        
        
        
        
        //CREATE DICTIONARY FROM PERSISTENT PLIST DATA
        func createDictionary(fromPlistWithName plistFile: String, completion: (_ result: NSMutableDictionary?, _ error: PlistManagerError?) -> ()) {
            
            if let plist = Plist(plistName: plistFile) {
            
                guard let dict = plist.createMutablePlist() else {
                    plistManagerPrint("unable to find: \(plistFile).plist")
                    completion(nil, .plistUnavailable)
                    return
                }
                //plistManagerPrint("temporary dictionary made from \(plistFile).plist")
                completion(dict, .plistAvailable)
            }
        }
        
        
        
        
        //CHECK IF KEY EXISTS IN PERSISTENT PLIST
        func checkDictionaryKeyExists(forKey key: String, inPlist plistKeys: Array<Any>, withPlistName plistFile: String) -> String {

            var returnString: String = ""
            
            if plistKeys.count != 0 {
              for (_, element) in plistKeys.enumerated() {
                if element as? String == key {
                    plistManagerPrint("'\(key)' found!")
                    returnString = element as! String
                    }
                }
            } else if plistKeys.count == 0 {
                plistManagerPrint("'\(key)' not found in \(plistFile).plist, the Plist is empty!")
                returnString = ""
            }
            return returnString
        }
        
        
        
        
        
        
        //ADD VALUE TO PERSISTENT PLIST
        func addValueToPersistentPlist(withData dict: NSMutableDictionary, forPlist plistFile: String, completion: (_ error: PlistManagerError?) -> ()) {
            
            if let plist = Plist(plistName: plistFile) {

              do {
                try plist.addValuesToPersistentPlist(dictionary: dict)
                completion(nil)
              } catch {
                plistManagerPrint(error)
                completion(error as? PlistManagerError)
              }
              
              logAction(forPlist: plist, withPlistName: plistFile)
              
            } else {
              plistManagerPrint("Unable to find \(plistFile).plist")
              completion(.plistUnavailable)
            }
        }

        
}


    //PRINT HANDLER
    func plistManagerPrint(_ text: Any) {

        if SwiftyPlistManager.shared.logPlistManager {
        print("[SwiftyPlistManager]", text)
      }
    }
