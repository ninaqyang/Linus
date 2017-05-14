//
//  ServiceHelper.swift
//  Linus
//
//  Created by Nina Yang on 5/14/17.
//  Copyright © 2017 Nina Yang. All rights reserved.
//

import Alamofire
import SwiftyJSON

class ServiceHelper {
    let coordinates = LocationManager.sharedInstance.getCoordinateData()
    
    func sendLocationOfUser() {
        guard let coordinates = coordinates, let x = coordinates.first, let y = coordinates.last else { return }
        let url = "robowaiter.tech/coffee_queue.php?push&quat_z=0.892&quat_w=-1.5&point_x=" + "\(x)" + "&point_y=" + "\(y)"

        Alamofire.request(url, method: .post, parameters: nil, encoding: JSONEncoding.default)
            .responseJSON { response in
                
                if let JSON = response.result.value {
                    print("JSON: \(JSON)")
                } else if response.result.error != nil {
                    print("Post request error: \(response.result.error!)")
                    return
                }
        }
    }
    
}
