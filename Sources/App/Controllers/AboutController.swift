//
//  Copyright © 2018 HomeKitty. All rights reserved.
//

import Vapor
import HTTP
import Leaf

public final class AboutController {
    
    init(router: Router) {
        router.get("about", use: about)
    }
    
    func about(_ req: Request) throws -> Future<View> {
        let leaf = try req.view()
        return leaf.render("about")
    }
}
