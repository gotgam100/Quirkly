//
//  GoofWidgetBundle.swift
//  GoofWidget
//
//  Created by BAEKMAC on 4/14/26.
//

import WidgetKit
import SwiftUI

@main
struct GoofWidgetBundle: WidgetBundle {
    var body: some Widget {
        GoofWidget()
        GoofWidgetControl()
        GoofWidgetLiveActivity()
    }
}
