//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//


import XCTest
@testable import Wire

final class FullscreenImageViewControllerSnapshotTests: ZMSnapshotTestCase {
    
    var sut: FullscreenImageViewController!

    override func setUp() {
        super.setUp()
        UIView.setAnimationsEnabled(false)

        sut = createFullscreenImageViewControllerForTest(imageName: "unsplash_matterhorn_small_size", fileExtension: "jpg")
    }
    
    
    override func tearDown() {
        sut = nil
        UIView.setAnimationsEnabled(true)
        super.tearDown()
    }


    func testThatSmallImageIsCenteredInTheScreen(){
        verify(view: sut.view)
    }

    func testThatSmallImageIsScaledToFitTheScreenAfterDoubleTapped(){
        // GIVEN & WHEN
        doubleTap(fullscreenImageViewController: sut)

        // THEN
        verify(view: sut.view)
    }
}
