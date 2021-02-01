//
//  PieChart.swift
//  ModuleKit
//
//  Created by Serhiy Mytrovtsiy on 30/11/2020.
//  Using Swift 5.0.
//  Running on macOS 10.15.
//
//  Copyright © 2020 Serhiy Mytrovtsiy. All rights reserved.
//

import Cocoa
import StatsKit

public class PieChart: Widget {
    private var labelState: Bool = true
    
    private let store: UnsafePointer<Store>?
    private var chart: PieChartView = PieChartView(
        frame: NSRect(
            x: Constants.Widget.margin.x,
            y: Constants.Widget.margin.y,
            width: Constants.Widget.height,
            height: Constants.Widget.height
        ),
        segments: [], filled: true, drawValue: false
    )
    private var labelView: NSView? = nil
    
    private let size: CGFloat = Constants.Widget.height - (Constants.Widget.margin.y*2) + (Constants.Widget.margin.x*2)
    
    public init(preview: Bool, title: String, config: NSDictionary?, store: UnsafePointer<Store>?) {
        var widgetTitle: String = title
        self.store = store
        if config != nil {
            if let titleFromConfig = config!["Title"] as? String {
                widgetTitle = titleFromConfig
            }
        }
        
        super.init(.pieChart, title: widgetTitle, frame: CGRect(
            x: Constants.Widget.margin.x,
            y: Constants.Widget.margin.y,
            width: self.size,
            height: Constants.Widget.height - (Constants.Widget.margin.y*2)
        ), preview: preview)
        
        self.wantsLayer = true
        self.canDrawConcurrently = true
        
        if let store = self.store {
            self.labelState = store.pointee.bool(key: "\(self.title)_\(self.type.rawValue)_label", defaultValue: self.labelState)
        }
        
        if preview {
            if self.title == "CPU" {
                self.chart.setSegments([
                    circle_segment(value: 0.16, color: NSColor.systemRed),
                    circle_segment(value: 0.28, color: NSColor.systemBlue)
                ])
            } else if self.title == "RAM" {
                self.chart.setSegments([
                    circle_segment(value: 0.36, color: NSColor.systemBlue),
                    circle_segment(value: 0.12, color: NSColor.systemOrange),
                    circle_segment(value: 0.08, color: NSColor.systemPink)
                ])
            }
        }
        
        self.draw()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func draw() {
        let x: CGFloat = self.labelState ? 8 + Constants.Widget.spacing : 0
        
        self.labelView = WidgetLabelView(self.title, height: self.frame.height)
        self.labelView!.isHidden = !self.labelState
        
        self.addSubview(self.labelView!)
        self.addSubview(self.chart)
        
        var frame = self.chart.frame
        frame = NSRect(x: x, y: 0, width: self.frame.size.height, height: self.frame.size.height)
        self.chart.frame = frame
        
        self.setFrameSize(NSSize(width: self.size + x, height: self.frame.size.height))
    }
    
    public func setValue(_ segments: [circle_segment]) {
        DispatchQueue.main.async(execute: {
            self.chart.setSegments(segments)
        })
    }
    
    // MARK: - Settings
    
    public override func settings(superview: NSView) {
        let rowHeight: CGFloat = 30
        let height: CGFloat = ((rowHeight + Constants.Settings.margin) * 1) + Constants.Settings.margin
        superview.setFrameSize(NSSize(width: superview.frame.width, height: height))
        
        let view: NSView = NSView(frame: NSRect(
            x: Constants.Settings.margin,
            y: Constants.Settings.margin,
            width: superview.frame.width - (Constants.Settings.margin*2),
            height: superview.frame.height - (Constants.Settings.margin*2)
        ))
        
        view.addSubview(ToggleTitleRow(
            frame: NSRect(x: 0, y: 0, width: view.frame.width, height: rowHeight),
            title: LocalizedString("Label"),
            action: #selector(toggleLabel),
            state: self.labelState
        ))
        
        superview.addSubview(view)
    }
    
    @objc private func toggleLabel(_ sender: NSControl) {
        var state: NSControl.StateValue? = nil
        if #available(OSX 10.15, *) {
            state = sender is NSSwitch ? (sender as! NSSwitch).state: nil
        } else {
            state = sender is NSButton ? (sender as! NSButton).state: nil
        }
        
        self.labelState = state! == .on ? true : false
        self.store?.pointee.set(key: "\(self.title)_\(self.type.rawValue)_label", value: self.labelState)
        
        let x = self.labelState ? 6 + Constants.Widget.spacing : 0
        self.labelView!.isHidden = !self.labelState
        self.chart.setFrameOrigin(NSPoint(x: x, y: 0))
        self.setWidth(self.labelState ? self.size+x : self.size)
    }
}
