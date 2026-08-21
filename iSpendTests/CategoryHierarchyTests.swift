import Testing
@testable import iSpend

struct CategoryHierarchyTests {
    @Test func rootCategoryHasNoParent() {
        let category = FinanceCategory(name: "餐饮", symbolName: "fork.knife", colorHex: "#FF6B5E", type: .expense)
        #expect(category.parentName == nil)
        #expect(category.displayName == "餐饮")
        #expect(category.pathDisplayName == "餐饮")
    }

    @Test func subcategoryExposesBothLevels() {
        let category = FinanceCategory(name: "餐饮/早餐", symbolName: "cup.and.saucer", colorHex: "#FF6B5E", type: .expense)
        #expect(category.parentName == "餐饮")
        #expect(category.displayName == "早餐")
        #expect(category.pathDisplayName == "餐饮 › 早餐")
        #expect(category.isSubcategory)
    }

    @Test func storageNameBuildsStablePath() {
        #expect(FinanceCategory.storageName("早餐", parentName: "餐饮") == "餐饮/早餐")
        #expect(FinanceCategory.storageName("餐饮", parentName: nil) == "餐饮")
    }
}
