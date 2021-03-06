#if os(iOS)
import UIKit

// MARK: - Frame Collection View Controller -
//------------------------------------------------------------------------------
/// Displays a collection of frames and their images.
public class FrameCollectionViewController<M: MemeGenerator>: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    // MARK: - Aliases
    //--------------------------------------------------------------------------
    public typealias Selection = (FrameCollectionViewController<M>?, FrameImage<M>)
    public typealias SelectionCallback = (Selection) -> ()

    // MARK: - Private -
    //--------------------------------------------------------------------------
    private var selectionCallback: SelectionCallback? = nil
    
    // MARK: - Public -
    //--------------------------------------------------------------------------
    /**
     */
    public var itemsPerRow: CGFloat = 3.0

    /**
     The collection of frame images the controller is responsible for
     displaying.

     - note: When this value changes, it triggers a `reload()` on the collection
     view.
     */
    public var images: [FrameImage<M>] = [] {
        didSet {
            reload()
            images.forEach {
                $0.update { [weak self] in
                    if let frameImage = try? $0(), frameImage != nil {
                        self?.reload()
                    }
                }
            }
        }
    }

    /**
     This will determine the ratio of frame images in the collection.

     - `square`: displays every cell with equal width and height; however,
     meme text may appear clipped.

     - `default`: will display the cell correctly scaled
     down, preserving the original width and height of the source
     image.
     
     - note: Defaults to `square`.
     */
    public var preferredFrameImageRatio: FrameImageRatio = .square

    // MARK: - Computed -
    //--------------------------------------------------------------------------
    /**
     A convenience accessor for the collection view's layout object.
     */
    public var flowLayout: UICollectionViewFlowLayout! {
        return collectionView?.collectionViewLayout as! UICollectionViewFlowLayout
    }

    // MARK: - Initialization -
    //--------------------------------------------------------------------------
    public required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder) }
    public required init(_ selectionCallback: SelectionCallback? = nil) {
        super.init(collectionViewLayout: UICollectionViewFlowLayout())
        self.selectionCallback = selectionCallback
    }

    // MARK: - Reload -
    //--------------------------------------------------------------------------
    public func reload() {
        DispatchQueue.main.async { [weak self] in
            self?.collectionView?.reloadData()
        }
    }

    // MARK: - View Lifecycle -
    //--------------------------------------------------------------------------
    public override func viewDidLoad() {
        super.viewDidLoad()

        // Collection View
        //----------------------------------------------------------------------
        collectionView?.backgroundColor = .simpsonsYellow
        collectionView?.alwaysBounceHorizontal = false
        collectionView?.keyboardDismissMode = .onDrag

        // If 'FrameImageCell' has a shadow, turning off clipping helps
        collectionView?.clipsToBounds = false

        // Cell Types
        //----------------------------------------------------------------------
        collectionView?.register(FrameImageCell.self, forCellWithReuseIdentifier: FrameImageCell.cellIdentifier)
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        reload()
    }

    // MARK: - Collection View, Data Source -
    //--------------------------------------------------------------------------
    public final override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    public final override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }

    public override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return dequeue(frameCellAt: indexPath)
    }

    public override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let frameImage = frameImage(at: indexPath) {
            selectionCallback?((self, frameImage))
        }
    }

    // MARK: - Dequeue Cell -
    //--------------------------------------------------------------------------
    public func dequeue(frameCellAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView?.dequeueReusableCell(withReuseIdentifier: FrameImageCell.cellIdentifier, for: indexPath) as! FrameImageCell
        cell.imageView.image = frameImage(at: indexPath)?.image

        return cell
    }

    // MARK: - Scroll to Frame Image -
    //--------------------------------------------------------------------------
    final func scroll(to frameImage: FrameImage<M>?, at position: UICollectionViewScrollPosition = .centeredHorizontally, animated: Bool = true) {
        if let frameImage = frameImage
            , let indexPath = indexPath(of: frameImage) {
            collectionView?.scrollToItem(at: indexPath, at: position, animated: animated)
        }
    }

    // MARK: - Collection View, Flow Layout Delegate -
    //--------------------------------------------------------------------------
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let frameImage = frameImage(at: indexPath) else {
            return .zero
        }

        //----------------------------------------------------------------------
        var allowableWidth: CGFloat = 0.0
        do {
            allowableWidth = try collectionView.allowableWidth(itemsPerRow: itemsPerRow)
        } catch {
            fatalError()
        }
        //----------------------------------------------------------------------

        // We stop here if the image doesn't have a `size`, or the preferreed
        // ratio is already set to `square`
        guard let imageSize = frameImage.image?.size, preferredFrameImageRatio != .square else {
            return CGSize(width: allowableWidth, height: allowableWidth)
        }

        let yScale = (allowableWidth / imageSize.width)
        var itemSize = CGSize(width: allowableWidth, height: imageSize.height)
            .applying(CGAffineTransform(scaleX: 1.0, y: yScale))

        // Determines if height of the collection view is less than `itemSize`
        // Note: similar to `allowableItemWith(_:, _:)`.
        let viewHeight = collectionView.bounds.height
            .subtracting(flowLayout.sectionInset.top)
            .subtracting(flowLayout.sectionInset.bottom)
            .subtracting(collectionView.contentInset.top)
            .subtracting(collectionView.contentInset.bottom)
        let xScale = (viewHeight / itemSize.height)
        if xScale.isLess(than: 1.0) {
            itemSize = itemSize.applying(CGAffineTransform(scaleX: xScale, y: xScale))
        }
        return itemSize
    }
}

// MARK: - Extension, Frame Image Subscripts -
//------------------------------------------------------------------------------
extension FrameCollectionViewController {
    /**
     Returns the `FrameImage` (or `nil`) for the given `index` within `images`.
     
     - parameter index: The subscript `index` for the given `FrameImage`.
     */
    fileprivate func frameImage(at index: Int) -> FrameImage<M>? {
        return images
            .enumerated()
            .filter { $0.offset == index }
            .first?.element
    }

    /**
     Returns an `IndexPath` (or `nil`) for the given `FrameImage`. 
     
     - parameter frameImage: The `FrameImage` being referenced.
     - parameter section: Assumes `0`.
        
     - note: Manually specify the `section` that you want `IndexPath` to have.
     */
    func indexPath(of frameImage: FrameImage<M>, section: Int = 0) -> IndexPath? {
        return images
            .enumerated()
            .filter { $0.element == frameImage }
            .map { IndexPath(row: $0.offset, section: section) }
            .first
    }

    /**
     Returns the `FrameImage` (or `nil`) for the given `IndexPath`.
     
     - parameter indexPath: The refereced `IndexPath`.
     */
    func frameImage(at indexPath: IndexPath) -> FrameImage<M>? {
        return frameImage(at: indexPath.row)
    }
}
#endif

public enum FrameImageRatio {
    case square
    case `default`
}
