import Testing
@testable import Charstack

@Suite("Region Enum Tests")
struct RegionTests {

    @Test("All cases are present")
    func allCasesExist() {
        #expect(Region.allCases.count == 4)
        #expect(Region.allCases.contains(.morning))
        #expect(Region.allCases.contains(.afternoon))
        #expect(Region.allCases.contains(.evening))
        #expect(Region.allCases.contains(.backlog))
    }

    @Test("Display names are correct")
    func displayNames() {
        #expect(Region.morning.displayName == "Morning")
        #expect(Region.afternoon.displayName == "Afternoon")
        #expect(Region.evening.displayName == "Evening")
        #expect(Region.backlog.displayName == "Backlog")
    }

    @Test("Sort order is Morning < Afternoon < Evening < Backlog")
    func sortOrder() {
        #expect(Region.morning < Region.afternoon)
        #expect(Region.afternoon < Region.evening)
        #expect(Region.evening < Region.backlog)
    }

    @Test("Active regions excludes Backlog")
    func activeRegions() {
        let activeRegions = Region.activeRegions
        #expect(activeRegions.count == 3)
        #expect(activeRegions.contains(.morning))
        #expect(activeRegions.contains(.afternoon))
        #expect(activeRegions.contains(.evening))
        #expect(!activeRegions.contains(.backlog))
    }

    @Test("isConstrained is true for active regions, false for backlog")
    func constrainedRegions() {
        #expect(Region.morning.isConstrained)
        #expect(Region.afternoon.isConstrained)
        #expect(Region.evening.isConstrained)
        #expect(!Region.backlog.isConstrained)
    }

    @Test("Raw values encode correctly for Codable/SwiftData")
    func rawValues() {
        #expect(Region.morning.rawValue == "morning")
        #expect(Region.afternoon.rawValue == "afternoon")
        #expect(Region.evening.rawValue == "evening")
        #expect(Region.backlog.rawValue == "backlog")
    }

    @Test("System image names are non-empty")
    func systemImageNames() {
        for region in Region.allCases {
            #expect(!region.systemImageName.isEmpty)
        }
    }
}
