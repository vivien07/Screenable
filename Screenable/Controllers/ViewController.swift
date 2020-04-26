import Cocoa


class ViewController: NSViewController {
    
    
    var screenshotImage: NSImage?
    var document: Document {
        let oughtToBeDocument = view.window?.windowController?.document as? Document
        assert(oughtToBeDocument != nil, "Unable to find the document for this view controller.")   //crash if it is nil
        return oughtToBeDocument!
    }
    
    
    @IBOutlet var imageView: NSImageView!
    @IBOutlet var caption: NSTextView!
    @IBOutlet var fontName: NSPopUpButton!
    @IBOutlet var fontSize: NSPopUpButton!
    @IBOutlet var fontColor: NSColorWell!
    
    @IBOutlet var backgroundImage: NSPopUpButton!
    @IBOutlet var backgroundColorStart: NSColorWell!
    @IBOutlet var backgroundColorEnd: NSColorWell!
    
    @IBOutlet var dropShadowStrength: NSSegmentedControl!
    @IBOutlet var dropShadowTarget: NSSegmentedControl!
    
    
    @objc func changeFontName(_ sender: NSMenuItem) {
        setFontName(to: fontName.titleOfSelectedItem ?? "")
    }
    
    @objc func setFontName(to name: String) {
        
        // register the undo point with the current font name
        undoManager?.registerUndo(withTarget: self, selector: #selector(setFontName), object: document.screenshot.captionFontName)
        // update the font name
        document.screenshot.captionFontName = name
        // update the UI to match
        fontName.selectItem(withTitle: document.screenshot.captionFontName)
        // ensure the preview is updated
        generatePreview()
        
    }
    
    
    @IBAction func changeFontSize(_ sender: NSMenuItem) {
        setFontSize(to: String(fontSize.selectedTag()))
    }
    
    
    @objc func setFontSize(to size: String) {
        
        undoManager?.registerUndo(withTarget: self, selector: #selector(setFontSize), object: String(document.screenshot.captionFontSize))
        document.screenshot.captionFontSize = Int(size)!
        fontSize.selectItem(withTag: document.screenshot.captionFontSize)
        generatePreview()
        
    }
    
    
    @IBAction func changeFontColor(_ sender: Any) {
        setFontColor(to: fontColor.color)
    }
    
    
    @objc func setFontColor(to color: NSColor) {
        
        undoManager?.registerUndo(withTarget: self, selector: #selector(setFontColor), object: document.screenshot.captionColor)
        document.screenshot.captionColor = color
        fontColor.color = color
        generatePreview()
        
    }
    
    
    @IBAction func changeBackgroundImage(_ sender: Any) {
        
        if backgroundImage.selectedTag() == 999 {
            setBackgroundImage(to: "")
        } else {
            setBackgroundImage(to: backgroundImage.titleOfSelectedItem ?? "")
        }
        
    }
    
    
    @objc func setBackgroundImage(to name: String) {
        
        undoManager?.registerUndo(withTarget: self, selector: #selector(setBackgroundImage), object: document.screenshot.backgroundImage)
        document.screenshot.backgroundImage = name
        backgroundImage.selectItem(withTitle: name)
        generatePreview()
    }
    
    
    @IBAction func changeBackgroundColorStart(_ sender: Any) {
        setBackgroundColorStart(to: backgroundColorStart.color)
    }
    
    @objc func setBackgroundColorStart(to color: NSColor) {
        
        undoManager?.registerUndo(withTarget: self, selector: #selector(setBackgroundColorStart), object: document.screenshot.backgroundColorStart)
        document.screenshot.backgroundColorStart = color
        backgroundColorStart.color = color
        generatePreview()
        
    }
    
    
    @IBAction func changeBackgroundColorEnd(_ sender: Any) {
        setBackgroundColorEnd(to: backgroundColorEnd.color)
    }
    
    
    @objc func setBackgroundColorEnd(to color: NSColor) {
        
        undoManager?.registerUndo(withTarget: self, selector: #selector(setBackgroundColorEnd), object: document.screenshot.backgroundColorEnd)
        document.screenshot.backgroundColorEnd = color
        backgroundColorEnd.color = color
        generatePreview()
        
    }
    
    
    @IBAction func changeDropShadowStrength(_ sender: Any) {
        setDropShadowStrength(to: String(dropShadowStrength.selectedSegment))
    }
    
    
    @objc func setDropShadowStrength(to strength: String) {
        
        undoManager?.registerUndo(withTarget: self, selector: #selector(setDropShadowStrength), object: String(document.screenshot.dropShadowStrength))
        document.screenshot.dropShadowStrength = Int(strength)!
        dropShadowStrength.selectedSegment = document.screenshot.dropShadowStrength
        generatePreview()
        
    }
    
    @IBAction func changeDropShadowTarget(_ sender: Any) {
        setDropShadowTarget(to: String(dropShadowTarget.selectedSegment))
    }
    
    
    @objc func setDropShadowTarget(to target: String) {
        
        undoManager?.registerUndo(withTarget: self, selector: #selector(setDropShadowTarget), object: String(document.screenshot.dropShadowTarget))
        document.screenshot.dropShadowTarget = Int(target)!
        dropShadowTarget.selectedSegment = document.screenshot.dropShadowTarget
        generatePreview()
        
    }
    
    
    @IBAction func export(_ sender: Any) {
        
        guard let image = imageView.image else { return }
        guard let tiffData = image.tiffRepresentation else { return }
        guard let imageRep = NSBitmapImageRep(data: tiffData) else { return }
        guard let png = imageRep.representation(using: .png, properties: [:]) else { return }
        
        let panel = NSSavePanel()   //A panel that prompts the user for information about where to save a file.
        panel.allowedFileTypes = ["jpg", "png"]
        panel.begin { result in
            if result == .OK {
                guard let URL = panel.url else { return }
                do {
                    try png.write(to: URL)
                } catch  {
                    //CHANGES NEED TO BE MADE HERE
                    print(error.localizedDescription)
                }
            }
        }
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let recognizer = NSClickGestureRecognizer(target: self, action: #selector(importScreenshot))
        imageView.addGestureRecognizer(recognizer)
        loadFonts()
        loadBackgroundImages()
        
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        updateUI()
        generatePreview()
    }
    
    
    func loadFonts() {
        
        guard let fontFile = Bundle.main.url(forResource: "fonts", withExtension: nil) else { return } //find the list of fonts
        guard let fonts = try? String(contentsOf: fontFile) else { return } //load the file into a string
        let fontNames = fonts.components(separatedBy: "\n") //convert that string into an array by splitting on line breaks
        for font in fontNames {
            if font.hasPrefix(" ") {    //this is a font variation
                let item = NSMenuItem(title: font, action: #selector(changeFontName), keyEquivalent: "")
                item.target = self
                fontName.menu?.addItem(item)
            } else {    //this is a font family
                let item = NSMenuItem(title: font, action: nil, keyEquivalent: "")
                item.target = self
                item.isEnabled = false
                fontName.menu?.addItem(item)
            }
        }
        
    }
    
    
    func loadBackgroundImages() {
        
        let allImages = ["Antique Wood", "Autumn Leaves", "Autumn Sunset", "Autumn by the Lake", "Beach and Palm Tree", "Blue Skies", "Bokeh (Blue)", "Bokeh (Golden)", "Bokeh (Green)", "Bokeh (Orange)", "Bokeh (Rainbow)", "Bokeh (White)", "Burning Fire", "Cherry Blossom", "Coffee Beans", "Cracked Earth", "Geometric Pattern 1", "Geometric Pattern 2", "Geometric Pattern 3", "Geometric Pattern 4", "Grass", "Halloween", "In the Forest", "Jute Pattern", "Polka Dots (Purple)", "Polka Dots (Teal)", "Red Bricks", "Red Hearts", "Red Rose", "Sandy Beach", "Sheet Music", "Snowy Mountain", "Spruce Tree Needles", "Summer Fruits", "Swimming Pool", "Tree Silhouette", "Tulip Field", "Vintage Floral", "Zebra Stripes"]
        for image in allImages {
            let item = NSMenuItem(title: image, action: #selector(changeBackgroundImage), keyEquivalent: "")
            item.target = self
            backgroundImage.menu?.addItem(item)
        }
        
    }
    
    
    func generatePreview() {
        
        let image = NSImage(size: CGSize(width: 1242, height: 2208), flipped: false) { [unowned self] rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            self.clearBackground(context: ctx, rect: rect)
            self.drawBackgroundImage(rect: rect)
            self.drawColorOverlay(rect: rect)
            let captionOffset = self.drawCaption(context: ctx, rect: rect)
            self.drawDevice(context: ctx, rect: rect, captionOffset: captionOffset)
            self.drawScreenshot(context: ctx, rect: rect, captionOffset: captionOffset)
            return true
        }
        imageView.image = image
        
    }
    
    
    func clearBackground(context: CGContext, rect: CGRect) {
        context.setFillColor(NSColor.white.cgColor)
        context.fill(rect)
    }
    
    
    func drawBackgroundImage(rect: CGRect) {
        
        if backgroundImage.selectedTag() == 999 { return }  // if they chose no background image, bail out
        guard let title = backgroundImage.titleOfSelectedItem else { return }   // if we can't get the current title, bail out
        guard let image = NSImage(named: title) else { return } // if we can't convert that title to an image, bail out
        image.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1)
        
    }
    
    
    func drawColorOverlay(rect: CGRect) {
        let gradient = NSGradient(starting: backgroundColorStart.color, ending: backgroundColorEnd.color)
        gradient?.draw(in: rect, angle: -90)
    }
    
    
    func createCaptionAttributes() -> [NSAttributedString.Key: Any]? {
        
        let ps = NSMutableParagraphStyle()
        ps.alignment = .center
        let fontSizes: [Int: CGFloat] = [0: 48, 1: 56, 2: 64, 3: 72, 4: 80, 5: 96, 6: 128]
        guard let baseFontSize = fontSizes[fontSize.selectedTag()] else { return nil }
        let selectedFontName = fontName.selectedItem?.title.trimmingCharacters(in: .whitespacesAndNewlines) ?? "HelveticaNeue-Medium"
        guard let font = NSFont(name: selectedFontName, size: baseFontSize) else { return nil }
        let color = fontColor.color
        return [NSAttributedString.Key.paragraphStyle: ps, NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: color]
        
    }
    
    
    func setShadow() {
        
        let shadow = NSShadow()
        shadow.shadowOffset = CGSize.zero
        shadow.shadowColor = NSColor.black
        shadow.shadowBlurRadius = 50
        shadow.set()
        
    }
    
    
    func drawCaption(context: CGContext, rect: CGRect) -> CGFloat {
        
        if dropShadowStrength.selectedSegment != 0 {    //if the drop shadow is enabled and is set to "text" or "both"
            if dropShadowTarget.selectedSegment == 0 || dropShadowTarget.selectedSegment == 2 {
                setShadow()
            }
        }
        let string = caption.textStorage?.string ?? ""
        let captionAttributes = createCaptionAttributes()
        let attributedString = NSAttributedString(string: string, attributes: captionAttributes)
        let insetRect = rect.insetBy(dx: 40, dy: 20)  //Returns a rectangle that is smaller or larger than the source rectangle, with the same center point.
        attributedString.draw(in: insetRect)
        if dropShadowStrength.selectedSegment == 2 {
            if dropShadowTarget.selectedSegment == 0 || dropShadowTarget.selectedSegment == 2 {
                // create a stronger drop shadow by drawing again
                attributedString.draw(in: insetRect)
            }
        }
        // clear the shadow so it doesn't affect other stuff
        let noShadow = NSShadow()
        noShadow.set()
        let availableSpace = CGSize(width: insetRect.width, height: CGFloat.greatestFiniteMagnitude)
        let textFrame = attributedString.boundingRect(with: availableSpace, options: [.usesLineFragmentOrigin, .usesFontLeading])
        return textFrame.height
        
    }
    
    
    func drawDevice(context: CGContext, rect: CGRect, captionOffset: CGFloat) {
        
        guard let image = NSImage(named: "iPhone") else { return }  //load the image
        //in order to center the image in the X and Y axis
        let offsetX = (rect.size.width - image.size.width) / 2
        var offsetY = (rect.size.height - image.size.height) / 2
        offsetY -= captionOffset
        if dropShadowStrength.selectedSegment != 0 {
            if dropShadowTarget.selectedSegment == 1 || dropShadowTarget.selectedSegment == 2 {
                setShadow()
            }
        }
        image.draw(at: CGPoint(x: offsetX, y: offsetY), from: .zero, operation: .sourceOver, fraction: 1)
        if dropShadowStrength.selectedSegment == 2 {
            if dropShadowTarget.selectedSegment == 1 || dropShadowTarget.selectedSegment == 2 {
                // create a stronger drop shadow by drawing again
                image.draw(at: CGPoint(x: offsetX, y: offsetY), from: .zero, operation: .sourceOver, fraction: 1)
            }
        }
        // clear the shadow so it doesn't affect other stuff
        let noShadow = NSShadow()
        noShadow.set()
        
    }
    
    @objc func importScreenshot() {
        
        let panel = NSOpenPanel()   //prompt user to select files to open
        panel.allowedFileTypes = ["jpg", "png"]
        panel.begin { [unowned self] result in
            if result == .OK {
                guard let imageURL = panel.url else { return }
                self.screenshotImage = NSImage(contentsOf: imageURL)
                self.generatePreview()
            }
        }
        
    }
    
    
    func drawScreenshot(context: CGContext, rect: CGRect, captionOffset: CGFloat) {
        
        guard let screenshot = screenshotImage else { return }
        screenshot.size = CGSize(width: 891, height: 1584)
        let offsetY = 314 - captionOffset
        screenshot.draw(at: CGPoint(x: 176, y: offsetY), from: .zero, operation: .sourceOver, fraction: 1)
        
    }
    
    
    
    
}


extension ViewController: NSTextViewDelegate {
    
    
    func textDidChange(_ notification: Notification) {
        document.screenshot.caption = caption.string
        generatePreview()
    }
    
    
    func updateUI() {
        
        caption.string = document.screenshot.caption
        fontName.selectItem(withTitle: document.screenshot.captionFontName)
        fontSize.selectItem(withTag: document.screenshot.captionFontSize)
        fontColor.color = document.screenshot.captionColor
        if !document.screenshot.backgroundImage.isEmpty {
            backgroundImage.selectItem(withTitle: document.screenshot.backgroundImage)
        }
        backgroundColorStart.color = document.screenshot.backgroundColorStart
        backgroundColorEnd.color = document.screenshot.backgroundColorEnd
        dropShadowStrength.selectedSegment = document.screenshot.dropShadowStrength
        dropShadowTarget.selectedSegment = document.screenshot.dropShadowTarget
        
    }
    
}




