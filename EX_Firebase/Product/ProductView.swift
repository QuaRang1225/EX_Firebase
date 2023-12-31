//
//  ProductView.swift
//  EX_Firebase
//
//  Created by 유영웅 on 2023/06/14.
//

import SwiftUI
import Kingfisher
import FirebaseFirestore

@MainActor
final class ProductViewModel:ObservableObject{
    @Published var products:[Product] = []
    @Published var selectFilter:FilterOption? = nil
    @Published var selectCategoryFilter:CategoryOption? = nil
    private var lastDocument:DocumentSnapshot? = nil
    
    //
//    func getAllProdcut() async throws{
//        self.products = try await ProductManager.shared.getAllProducts()
//    }
    func downloadData(){    //한번만 실행
        guard let url = URL(string: "https://dummyjson.com/products") else {return}

        Task{
            do{
                let (data,_) = try await URLSession.shared.data(from: url)
                let product = try JSONDecoder().decode(DummyJson.self, from: data)
                let productArray = product.products

                for product in productArray {
                    try await ProductManager.shared.uploadProduct(product: product)
                }
                print("성공")
                print(product.products.count)
            }catch{
                print(error)
            }
        }
    }
    enum FilterOption:String,CaseIterable{
        case none
        case priceHigh
        case priceLow
        
        var categoryKey:String?{
            if self == .none{
                return nil
            }
            return self.rawValue
        }
        
        var priceDescending:Bool?{
            switch self{
            case .none: return nil
            case .priceHigh: return true
            case .priceLow: return false
            }
        }
    }
    enum CategoryOption:String,CaseIterable{
        case none
        case smartphones
        case laptops
        case fragrances
        
        var categoryKey:String?{
            if self == .none{
                return nil
            }
            return self.rawValue
        }
    }
    
    
    func filterSelected(option:FilterOption){
        self.selectFilter = option
        self.products = []
        self.lastDocument = nil
        self.getProduct()
    }
    func categorySelected(option:CategoryOption){

        self.selectCategoryFilter = option
        self.products = []
        self.lastDocument = nil
        self.getProduct()
    }
    
    
    func getProduct() {
        Task{
            let (newProduct,lastDocument)  = try await ProductManager.shared.getAllProducts(descending: selectFilter?.priceDescending, category: selectCategoryFilter?.categoryKey, count: 10,lastDocument: lastDocument)
           self.products.append(contentsOf: newProduct)
            if let lastDocument{
                self.lastDocument = lastDocument
            }
        }
    }
    func addUserFavoriteProduct(productId:Int){
        Task{
            let authDataReslut = try AuthenticationManager.shared.getUser()
            try? await UserManager.shared.addUserFavoriteProduct(userId:authDataReslut.uid,productId:productId) //실패할경우 예외처리 X
        }
    }
    
//    func getProductCount(){
//        Task{
//            let count = try await ProductManager.shared.allProductCount()
//            print("리스트 갯수\(count)")
//        }
//    }
//    func getProductByRationg(){
//        Task{
//            let (newProduct,lastDocument)  = try await ProductManager.shared.getProductByRationg(count: 3, lastDocument: lastDocument)
//            self.products.append(contentsOf: newProduct)
//            self.lastDocument = lastDocument
//        }
//    }
}

struct ProductView: View {
    @StateObject var vm = ProductViewModel()
    var body: some View {
        List{
//            Button("더보기"){
//                vm.getProductByRationg()
//            }
            ForEach(vm.products) { pro in
                ProductRowView(pro: pro)
                    .contextMenu{
                        Button("찜목록 추가"){
                            vm.addUserFavoriteProduct(productId: pro.id)
                        }
                    }
                if pro == vm.products.last{
                    ProgressView()
                        .onAppear{
                            vm.getProduct()
                        }
                }
            }
           
        }.navigationTitle("프로덕션")
            .toolbar{
                ToolbarItem(placement:.navigationBarLeading){
                    Menu("가격 필터 : \(vm.selectFilter?.rawValue ?? "none")"){
                        ForEach(ProductViewModel.FilterOption.allCases,id:\.self) { filter in
                            Button {
//                                Task{
//                                    try? await vm.filterSelected(option: filter)
//                                }
                                vm.filterSelected(option: filter)
                            } label: {
                                Text(filter.rawValue)
                            }
                        }
                    }
                }
                ToolbarItem(placement:.navigationBarTrailing){
                    Menu("제품 필터 : \(vm.selectCategoryFilter?.rawValue ?? "none")"){
                        ForEach(ProductViewModel.CategoryOption.allCases,id:\.self) { filter in
                            Button {
//                                Task{
//                                    vm.categorySelected(option: filter)
//                                }
                                vm.categorySelected(option: filter)
                            } label: {
                                Text(filter.rawValue)
                            }
                        }
                    }
                }
            }
        .onAppear {
            vm.getProduct()   //에러처리를 안했기 때문에 try? 형태를 쓴다
//            vm.getProductCount()
        }
    }
}

struct ProductView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack{
            ProductView()
        }
    }
}
