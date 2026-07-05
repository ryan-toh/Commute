//
//  DebugPrint.swift
//  Commute
//
//  Created by Ryan on 4/7/26.
//

func debugPrint(_ items: Any...) {
#if DEBUG
    print(items)
#endif
}
