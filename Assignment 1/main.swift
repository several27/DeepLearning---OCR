//
//  main.swift
//  Assignment 1
//
//  Created by Maciej Szpakowski on 30/01/2016.
//  Copyright © 2016 Maciej Szpakowski. All rights reserved.
//

import Foundation
import AppKit

func printndarray(elements: ndarray)
{
    var r = "["
    var count = 0
    for element in elements.grid
    {
        r = "\(r)\(element),"
        count++
        if count % 27 == 0
        {
            r = "\(r)\n"
        }
    }
    print("\(r)]")
}

func printFloatArray(elements: [Float])
{
    var r = "["
    var count = 0
    for element in elements
    {
        r = "\(r)\(element),"
        count++
        if count % 27 == 0
        {
            r = "\(r)\n"
        }
    }
    print("\(r)]")
}

func convertFolderOfImagesToMatrices(folderPath: String) -> [[Float]]?
{
    var matrices: [[Float]] = []
    
    let fileManager = NSFileManager.defaultManager()
    
    do
    {
        let contents = try fileManager.contentsOfDirectoryAtPath(folderPath)
//        var counter = 0
        
        for file in contents
        {
//            let fullPath = folderPath + file
//            if let image = NSImage(contentsOfFile: fullPath)
//            {
////                if counter % 100 == 0
////                {
////                    print("\(counter) out of \(contents.count)")
////                }
//                
////                matrices.append(convertImageMatrixToFloats(convertImageToMatrix(image)))
//            }

            let fullPath = folderPath + file
            let dataProvider = CGDataProviderCreateWithFilename(fullPath)
            if let image = CGImageCreateWithPNGDataProvider(dataProvider, nil, true, CGColorRenderingIntent.RenderingIntentDefault)
            {
                matrices.append(myFastConvertImageToMatrix(image))
            }
            
//            counter++
        }
    }
    catch { }
    
    return matrices
}

func fastConvertFolderOfImagesToMatrices(folderPath: String) -> [[Float]]?
{
    var matrices: [[Float]] = []
    
    let fileManager = NSFileManager.defaultManager()
    
    do
    {
        let contents = try fileManager.contentsOfDirectoryAtPath(folderPath)
        
        let accessQueue = dispatch_queue_create("SynchronizedArrayAccess", DISPATCH_QUEUE_SERIAL)
        
        let contentsArray: NSArray = contents as NSArray
        contentsArray.enumerateObjectsWithOptions(
            NSEnumerationOptions.Concurrent,
            usingBlock:
                {
                    (file: AnyObject, index: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
                    let fullPath = folderPath + (file as! String)
                    let dataProvider = CGDataProviderCreateWithFilename(fullPath)
                    if let image = CGImageCreateWithPNGDataProvider(dataProvider, nil, true, CGColorRenderingIntent.RenderingIntentDefault)
                    {
                        dispatch_async(accessQueue)
                            {
                                matrices.append(myFastConvertImageToMatrix(image))
                        }
                    }
                }
        )
    }
    catch { }
    
    return matrices
}

func convertImageToMatrix(image: NSImage) -> matrix
{
    let imageRep = image.representations[0]
    var imageMatrix = zeros(imageRep.pixelsWide * imageRep.pixelsHigh).reshape((imageRep.pixelsWide, imageRep.pixelsHigh))
    
    if let imageData = image.TIFFRepresentation
    {
        let imageBitMap = NSBitmapImageRep(data: imageData)
        
        for x in 1...imageRep.pixelsWide
        {
            for y in 1...imageRep.pixelsHigh
            {
                let initalArray = [0, 0, 0, 0]
                let pointer: UnsafeMutablePointer<Int> = UnsafeMutablePointer(initalArray)
                    
                imageBitMap?.getPixel(pointer, atX: x, y: y)
                
                let arrary = Array(UnsafeBufferPointer(start: pointer, count: initalArray.count))
                    
                imageMatrix[x - 1, y - 1] = Double(arrary[0])
            }
        }
    }
    
    return imageMatrix
}

//func fastConvertImageToMatrix(image: CGImage) -> (matrix, matrix, matrix, matrix)
func fastConvertImageToMatrix(image: CGImage) -> matrix
{
    let width = CGImageGetWidth(image)
    let height = CGImageGetHeight(image)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bytesPerPixel = 4
    let bytesPerRow:UInt = UInt(bytesPerPixel) * UInt(width)
    let bitsPerComponent:UInt = 8
    let pix = Int(width) * Int(height)
    let count:Int = 4*Int(pix)
    
    // pulling the color out of the image
    let rawData = UnsafeMutablePointer<UInt8>.alloc(4 * width * height)
    let temp = CGImageAlphaInfo.PremultipliedLast.rawValue
    let context = CGBitmapContextCreate(rawData, Int(width), Int(height), Int(bitsPerComponent), Int(bytesPerRow), colorSpace, temp)
    CGContextDrawImage(context, CGRectMake(0,0,CGFloat(width), CGFloat(height)), image)
    
    // unsigned char to double conversion
    var rawDataArray = zeros(count)-1
    vDSP_vfltu8D(rawData, 1.stride, !(rawDataArray), 1, count.length)
    
    // pulling the RGBA channels out of the color
    let i = arange(pix)
    var r = zeros((Int(height), Int(width))) - 1;
    r.flat = rawDataArray[4*i + 0]
    
    var g = zeros((Int(height), Int(width)));
    g.flat = rawDataArray[4*i + 1]
    
    var b = zeros((Int(height), Int(width)));
    b.flat = rawDataArray[4*i + 2]
    
    var a = zeros((Int(height), Int(width)));
    a.flat = rawDataArray[4*i + 3]
    
//    return (r, g, b, a)
    return r
}

func myFastConvertImageToMatrix(image: CGImage) -> [Float]
{
    let width = CGImageGetWidth(image)
    let height = CGImageGetHeight(image)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bytesPerPixel = 4
    let bytesPerRow:UInt = UInt(bytesPerPixel) * UInt(width)
    let bitsPerComponent:UInt = 8
    let pix = Int(width) * Int(height)
    let count:Int = 4 * Int(pix)

    // Pulling the color out of the image
    let rawData = UnsafeMutablePointer<UInt8>.alloc(4 * width * height)
    let temp = CGImageAlphaInfo.PremultipliedLast.rawValue
    let context = CGBitmapContextCreate(rawData, Int(width), Int(height), Int(bitsPerComponent), Int(bytesPerRow), colorSpace, temp)
    CGContextDrawImage(context, CGRectMake(0, 0, CGFloat(width), CGFloat(height)), image)
    
    // Unsigned char to double conversion
    var rawDataArray: [Float] = Array(count: count, repeatedValue: 0.0)
    vDSP_vfltu8(rawData, vDSP_Stride(1), &rawDataArray, 1, vDSP_Length(count))
    
    // Indices matrix
    var i: [Float] = Array(count: pix, repeatedValue: 0.0)
    var min: Float = 0.0
    var step: Float = 4.0
    vDSP_vramp(&min, &step, &i, vDSP_Stride(1), vDSP_Length(i.count))
    
    func increaseMatrix(var matrix: [Float]) -> [Float]
    {
        var increaser: Float = 1.0
        vDSP_vsadd(&matrix, vDSP_Stride(1), &increaser, &matrix, vDSP_Stride(1), vDSP_Length(i.count))
        
        return matrix
    }
    
    // Red matrix
    var r: [Float] = Array(count: pix, repeatedValue: 0.0)
    vDSP_vindex(&rawDataArray, &i, vDSP_Stride(1), &r, vDSP_Stride(1), vDSP_Length(r.count))
    
    var toSubstract: Float = 255.0 / 2.0
    vDSP_vsadd(&r, vDSP_Stride(1), &toSubstract, &r, vDSP_Stride(1), vDSP_Length(r.count))
    
    var divider: Float = 255.0
    vDSP_vsdiv(&r, vDSP_Stride(1), &divider, &r, vDSP_Stride(1), vDSP_Length(r.count))
    
    
//    for UInt8
//    var rI: [UInt8] = Array(count: pix, repeatedValue: 0)
//    vDSP_vfixru8(&r, vDSP_Stride(1), &rI, vDSP_Stride(1), vDSP_Length(r.count))
    
//    increaseMatrix(i)
//    // Green matrix
//    var g: [Float] = Array(count: pix, repeatedValue: 0.0)
//    vDSP_vindex(&rawDataArray, &i, vDSP_Stride(1), &g, vDSP_Stride(1), vDSP_Length(g.count))
//    
//    increaseMatrix(i)
//    // Blue matrix
//    var b: [Float] = Array(count: pix, repeatedValue: 0.0)
//    vDSP_vindex(&rawDataArray, &i, vDSP_Stride(1), &b, vDSP_Stride(1), vDSP_Length(b.count))
//    
//    increaseMatrix(i)
//    // Alpha matrix
//    var a: [Float] = Array(count: pix, repeatedValue: 0.0)
//    vDSP_vindex(&rawDataArray, &i, vDSP_Stride(1), &a, vDSP_Stride(1), vDSP_Length(a.count))
    
    return r
}

func convertImageMatrixToFloats(imageMatrix: matrix) -> matrix
{
    return (imageMatrix - (255 / 2)) / 255
}

//let image = NSImage(contentsOfFile: "/Users/maciej/Library/Mobile Documents/com~apple~CloudDocs/Study/Udacity/Deep Learning/Assignment 1/A.png")!

//var imageMatrix = convertImageToMatrix(image)
//print(imageMatrix)

//imageMatrix = convertImageMatrixToFloats(imageMatrix)
//print(imageMatrix)

let aFolderPath = "/Users/maciej/Library/Mobile Documents/com~apple~CloudDocs/Study/Udacity/Deep Learning/notMNIST_large/A/"
//
//var startTime = CFAbsoluteTimeGetCurrent()
//var matrices = convertFolderOfImagesToMatrices(aFolderPath)
//matrices?.removeAll()
//var timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
//print("Time elapsed for convertFolderOfImagesToMatrices: \(timeElapsed) s")

var startTime = CFAbsoluteTimeGetCurrent()
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// Time to get exactly the same result in python using their scipy: 16s
// Time to to execture function below: 5s 
// YUPI !!!
// Average memory usage: 300MB
// YUPI !!!
// First when I've written this algorithm it took 148s and 1800MB WOW
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// But
// without concurrent file reading it takes 32s 
// Dam dam daaammmmmmm
// :( :( :( :( :( :( :( :( :( :( :( :( :( :( :( :( :( :( :( :( :( :( :( :( :( :(
var matrices = fastConvertFolderOfImagesToMatrices(aFolderPath)
var timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
print("Time elapsed for fastConvertFolderOfImagesToMatrices: \(timeElapsed) s")

// Save matrices to file
var content = ""
for matrix in matrices!
{
    var count = 1
    for element in matrix
    {
        content += String(format: "%.5f", element) + (count % 28 == 0 ? "\n" : ",")
        count++
    }
    
    content += "\n"
}

//let file = "file.txt"
//if let dir : NSString = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.AllDomainsMask, true).first {
//    let path = dir.stringByAppendingPathComponent(file);
//    
do
{
    try content.writeToFile("/Users/maciej/Library/Mobile Documents/com~apple~CloudDocs/Study/Udacity/Deep Learning/A.txt", atomically: false, encoding: NSUTF8StringEncoding)
}
catch { }
    
//    //reading
//    do {
//        let text2 = try NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding)
//    }
//    catch {/* error handling here */}
//}


//sleep(1000)

//
//var source = [0, 100, 255]
//var destination: UnsafeMutablePointer<Double> = UnsafeMutablePointer([0.0, 0.0, 0.0])
//vDSP_vfltu8D(source, vDSP_Stride(1), destination, vDSP_Stride(1), vDSP_Length(3))
//
//print(source.memory)
//print(destination.memory)

//var result: Float = 0.0
//vDSP_maxv([10.0, 20.0, 30.0], 1, &result, vDSP_Length(3))
//print(result)

//func UInt8VectorToDoubleVector(source: [UInt8]) -> [Double]
//{
//    var result: [Double] = [0.0, 0.0, 0.0]
//    vDSP_vfltu8D(source, 1, &result, 1, vDSP_Length(3))
//    
//    return result
//}
//
//let source: [UInt8] = [0, 125, 255]
//print(source)
//
//var result: [Double] = [0.0, 0.0, 0.0]
//vDSP_vfltu8D(source, 1, &result, 1, vDSP_Length(3))
//
//print(result)


//let fullPath = aFolderPath + "a2F6b28udHRm.png"
//let dataProvider = CGDataProviderCreateWithFilename(fullPath)
//if let image = CGImageCreateWithPNGDataProvider(dataProvider, nil, true, CGColorRenderingIntent.RenderingIntentDefault)
//{
//    fastConvertImageToMatrix(image)
//    myFastConvertImageToMatrix(image)
//}












