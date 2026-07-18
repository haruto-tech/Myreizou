//
//  album.swift
//  Myreizou
//
//  Created by はると on 2026/07/04.
//

import SwiftUI
import SwiftData
import PhotosUI
import UIKit

struct AlbumView: View {
    var body: some View {
        NavigationStack {
            AlbumContentView()
        }
    }
}

struct AlbumContentView: View {
    @Query(sort: \AlbumFolder.createdAt, order: .reverse) private var folders: [AlbumFolder]
    @Query(sort: \AlbumPhoto.createdAt, order: .reverse) private var photos: [AlbumPhoto]

    @State private var isShowingAddFolder = false
    @State private var displayMode: AlbumDisplayMode = .albums
    @State private var selectedPhoto: AlbumPhoto?
    @State private var folderSortOption: AlbumFolderSortOption = .updatedAt
    @State private var photoSortOption: AlbumPhotoSortOption = .newest

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Picker("表示", selection: $displayMode) {
                    ForEach(AlbumDisplayMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                switch displayMode {
                case .albums:
                    if sortedFolders.isEmpty {
                        ContentUnavailableView(
                            "アルバムファイルがありません",
                            systemImage: "folder.badge.plus",
                            description: Text("右下の＋からファイルを作成できます。")
                        )
                        .padding(.top, 64)
                    } else {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(sortedFolders) { folder in
                                NavigationLink {
                                    AlbumFolderDetailView(folder: folder)
                                } label: {
                                    AlbumFolderGridItem(folder: folder)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }

                case .allPhotos:
                    AllAlbumPhotosGrid(photos: sortedPhotos) { photo in
                        selectedPhoto = photo
                    }
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 96)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("アルバム")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    switch displayMode {
                    case .albums:
                        Picker("並び替え", selection: $folderSortOption) {
                            ForEach(AlbumFolderSortOption.allCases) { option in
                                Label(option.title, systemImage: option.systemImage)
                                    .tag(option)
                            }
                        }

                    case .allPhotos:
                        Picker("並び替え", selection: $photoSortOption) {
                            ForEach(AlbumPhotoSortOption.allCases) { option in
                                Label(option.title, systemImage: option.systemImage)
                                    .tag(option)
                            }
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                }
                .accessibilityLabel("並び替え")
            }
        }
        .overlay(alignment: .bottomTrailing) {
            AlbumFloatingAddButton(accessibilityLabel: "ファイルを作成") {
                isShowingAddFolder = true
            }
            .padding(.trailing, 28)
            .padding(.bottom, 24)
        }
        .sheet(isPresented: $isShowingAddFolder) {
            AddAlbumFolderView()
        }
        .fullScreenCover(item: $selectedPhoto) { photo in
            AlbumPhotoFullScreenView(photo: photo)
        }
    }

    private var sortedFolders: [AlbumFolder] {
        folders.sorted { first, second in
            switch folderSortOption {
            case .updatedAt:
                return first.updatedAt > second.updatedAt
            case .createdAt:
                return first.createdAt > second.createdAt
            case .name:
                let result = first.name.compare(
                    second.name,
                    options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive],
                    locale: Locale(identifier: "ja_JP")
                )

                if result != .orderedSame {
                    return result == .orderedAscending
                }

                return first.updatedAt > second.updatedAt
            case .photoCount:
                if first.photos.count != second.photos.count {
                    return first.photos.count > second.photos.count
                }

                return first.updatedAt > second.updatedAt
            }
        }
    }

    private var sortedPhotos: [AlbumPhoto] {
        photos.sorted { first, second in
            switch photoSortOption {
            case .newest:
                return first.createdAt > second.createdAt
            case .oldest:
                return first.createdAt < second.createdAt
            }
        }
    }
}

private enum AlbumDisplayMode: String, CaseIterable, Identifiable {
    case albums
    case allPhotos

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .albums:
            return "アルバム"
        case .allPhotos:
            return "すべての写真"
        }
    }
}

private enum AlbumFolderSortOption: String, CaseIterable, Identifiable {
    case updatedAt
    case createdAt
    case name
    case photoCount

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .updatedAt:
            return "更新が新しい順"
        case .createdAt:
            return "作成が新しい順"
        case .name:
            return "名前順"
        case .photoCount:
            return "写真が多い順"
        }
    }

    var systemImage: String {
        switch self {
        case .updatedAt:
            return "clock.arrow.circlepath"
        case .createdAt:
            return "calendar.badge.plus"
        case .name:
            return "textformat.abc"
        case .photoCount:
            return "photo.stack"
        }
    }
}

private enum AlbumPhotoSortOption: String, CaseIterable, Identifiable {
    case newest
    case oldest

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .newest:
            return "新しい順"
        case .oldest:
            return "古い順"
        }
    }

    var systemImage: String {
        switch self {
        case .newest:
            return "arrow.down"
        case .oldest:
            return "arrow.up"
        }
    }
}

private struct AlbumFloatingAddButton: View {
    let accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.title.weight(.regular))
                .foregroundStyle(.primary)
                .frame(width: 64, height: 64)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

private struct AlbumFolderGridItem: View {
    let folder: AlbumFolder

    private var sortedPhotos: [AlbumPhoto] {
        folder.photos.sorted { first, second in
            first.createdAt > second.createdAt
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if sortedPhotos.isEmpty {
                ZStack {
                    Rectangle()
                        .fill(Color(.secondarySystemGroupedBackground))

                    Image(systemName: "folder")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                }
                .aspectRatio(1, contentMode: .fill)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                AlbumFolderPreviewGrid(photos: sortedPhotos)
            }

            Text(folder.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)

            Text("\(folder.photos.count)枚")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct AlbumFolderPreviewGrid: View {
    let photos: [AlbumPhoto]

    var body: some View {
        GeometryReader { geometry in
            let spacing: CGFloat = 2
            let side = (geometry.size.width - spacing) / 2
            let columns = [
                GridItem(.fixed(side), spacing: spacing),
                GridItem(.fixed(side), spacing: spacing)
            ]

            LazyVGrid(columns: columns, spacing: spacing) {
                ForEach(0..<4, id: \.self) { index in
                    if index < photos.count {
                        AlbumImage(data: photos[index].imageData)
                            .frame(width: side, height: side)
                            .clipped()
                    } else {
                        Color(.secondarySystemGroupedBackground)
                            .frame(width: side, height: side)
                    }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct AllAlbumPhotosGrid: View {
    let photos: [AlbumPhoto]
    let select: (AlbumPhoto) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

    var body: some View {
        if photos.isEmpty {
            ContentUnavailableView(
                "写真がありません",
                systemImage: "photo.on.rectangle",
                description: Text("アルバムファイルに写真を追加すると表示されます。")
            )
            .padding(.top, 64)
        } else {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(photos) { photo in
                    Button {
                        select(photo)
                    } label: {
                        AlbumSquareThumbnail(data: photo.imageData, cornerRadius: 0)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct AlbumFolderDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let folder: AlbumFolder

    @State private var isShowingAddPhotos = false
    @State private var isShowingDeleteConfirmation = false
    @State private var selectedPhoto: AlbumPhoto?
    @State private var errorMessage: String?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var sortedPhotos: [AlbumPhoto] {
        folder.photos.sorted { first, second in
            first.createdAt > second.createdAt
        }
    }

    var body: some View {
        ScrollView {
            if sortedPhotos.isEmpty {
                ContentUnavailableView(
                    "写真がありません",
                    systemImage: "photo.on.rectangle",
                    description: Text("右下の＋から写真を追加できます。")
                )
                .padding(.top, 80)
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(sortedPhotos) { photo in
                        Button {
                            selectedPhoto = photo
                        } label: {
                            AlbumPhotoGridItem(photo: photo)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(folder.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    isShowingDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                }
                .accessibilityLabel("ファイルを削除")
            }
        }
        .overlay(alignment: .bottomTrailing) {
            AlbumFloatingAddButton(accessibilityLabel: "写真を追加") {
                isShowingAddPhotos = true
            }
            .padding(.trailing, 28)
            .padding(.bottom, 24)
        }
        .sheet(isPresented: $isShowingAddPhotos) {
            AddAlbumPhotosView(folder: folder)
        }
        .fullScreenCover(item: $selectedPhoto) { photo in
            AlbumPhotoFullScreenView(photo: photo)
        }
        .confirmationDialog("このファイルを削除しますか？", isPresented: $isShowingDeleteConfirmation, titleVisibility: .visible) {
            Button("削除", role: .destructive) {
                deleteFolder()
            }
        }
        .alert("削除できませんでした", isPresented: errorBinding) {
            Button("OK", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    errorMessage = nil
                }
            }
        )
    }

    private func deleteFolder() {
        modelContext.delete(folder)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct AlbumPhotoGridItem: View {
    let photo: AlbumPhoto

    var body: some View {
        AlbumSquareThumbnail(data: photo.imageData)
    }
}

struct AlbumPhotoFullScreenView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let photo: AlbumPhoto

    @State private var isShowingDeleteConfirmation = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            AlbumImage(data: photo.imageData, contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(spacing: 0) {
                HStack {
                    AlbumFullScreenButton(systemImage: "xmark") {
                        dismiss()
                    }
                        .accessibilityLabel("閉じる")

                    Spacer()

                    AlbumFullScreenButton(systemImage: "trash") {
                        isShowingDeleteConfirmation = true
                    }
                    .accessibilityLabel("写真を削除")
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                Spacer()

                if !photo.memo.isEmpty {
                    Text(photo.memo)
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 28)
                }
            }
        }
        .confirmationDialog("この写真を削除しますか？", isPresented: $isShowingDeleteConfirmation, titleVisibility: .visible) {
            Button("削除", role: .destructive) {
                deletePhoto()
            }
        }
        .alert("削除できませんでした", isPresented: errorBinding) {
            Button("OK", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    errorMessage = nil
                }
            }
        )
    }

    private func deletePhoto() {
        if let folder = photo.folder {
            folder.updatedAt = Date()
        }

        modelContext.delete(photo)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct AlbumFullScreenButton: View {
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

private struct AddAlbumFolderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var memo = ""
    @State private var errorMessage: String?

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("ファイル") {
                    TextField("ファイル名 例: 文化祭", text: $name)
                    TextField("メモ", text: $memo, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("ファイルを作成")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("作成") {
                        addFolder()
                    }
                }
            }
            .alert("作成できませんでした", isPresented: errorBinding) {
                Button("OK", role: .cancel) {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    errorMessage = nil
                }
            }
        )
    }

    private func addFolder() {
        let now = Date()
        let folder = AlbumFolder(
            name: trimmedName.isEmpty ? "新しいファイル" : trimmedName,
            memo: memo.trimmingCharacters(in: .whitespacesAndNewlines),
            createdAt: now,
            updatedAt: now
        )

        modelContext.insert(folder)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct AddAlbumPhotosView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let folder: AlbumFolder

    @State private var memo = ""
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var imageDatas: [Data] = []
    @State private var isLoadingImages = false
    @State private var errorMessage: String?

    private var canSave: Bool {
        !imageDatas.isEmpty && !isLoadingImages
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("写真") {
                    PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 20, matching: .images) {
                        Label(imageDatas.isEmpty ? "写真を選ぶ" : "\(imageDatas.count)枚選択中", systemImage: "photo")
                    }

                    if isLoadingImages {
                        ProgressView("読み込み中")
                    } else if !imageDatas.isEmpty {
                        Text("\(imageDatas.count)枚を追加します")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("メモ") {
                    TextField("写真共通のメモ", text: $memo, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("写真を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        addPhotos()
                    }
                    .disabled(!canSave)
                }
            }
            .onChange(of: selectedPhotos) { _, newPhotos in
                Task {
                    await loadImages(from: newPhotos)
                }
            }
            .alert("保存できませんでした", isPresented: errorBinding) {
                Button("OK", role: .cancel) {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    errorMessage = nil
                }
            }
        )
    }

    @MainActor
    private func loadImages(from photos: [PhotosPickerItem]) async {
        guard !photos.isEmpty else {
            imageDatas = []
            return
        }

        isLoadingImages = true
        defer {
            isLoadingImages = false
        }

        var loadedImages: [Data] = []

        for photo in photos {
            do {
                if let data = try await photo.loadTransferable(type: Data.self) {
                    loadedImages.append(compressedImageData(from: data))
                }
            } catch {
                errorMessage = error.localizedDescription
                return
            }
        }

        imageDatas = loadedImages
    }

    private func addPhotos() {
        guard !imageDatas.isEmpty else {
            errorMessage = "写真を選んでください。"
            return
        }

        let now = Date()
        let trimmedMemo = memo.trimmingCharacters(in: .whitespacesAndNewlines)

        for imageData in imageDatas {
            let photo = AlbumPhoto(
                imageData: imageData,
                memo: trimmedMemo,
                createdAt: now,
                updatedAt: now
            )

            folder.photos.append(photo)
            modelContext.insert(photo)
        }

        folder.updatedAt = now

        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct AlbumSquareThumbnail: View {
    let data: Data
    var cornerRadius: CGFloat = 8

    var body: some View {
        GeometryReader { geometry in
            AlbumImage(data: data)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

private struct AlbumImage: View {
    let data: Data
    var contentMode: ContentMode = .fill

    var body: some View {
        if let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: contentMode)
        } else {
            ZStack {
                Rectangle()
                    .fill(Color(.secondarySystemGroupedBackground))

                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private func compressedImageData(from data: Data) -> Data {
    guard let image = UIImage(data: data) else {
        return data
    }

    let maxSide: CGFloat = 1600
    let longestSide = max(image.size.width, image.size.height)

    guard longestSide > maxSide else {
        return image.jpegData(compressionQuality: 0.82) ?? data
    }

    let scale = maxSide / longestSide
    let targetSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
    let renderer = UIGraphicsImageRenderer(size: targetSize)

    return renderer.jpegData(withCompressionQuality: 0.82) { _ in
        image.draw(in: CGRect(origin: .zero, size: targetSize))
    }
}

typealias album = AlbumView

#Preview {
    AlbumView()
        .modelContainer(
            for: [FoodItem.self, FoodCategory.self, AlbumEntry.self, AlbumFolder.self, AlbumPhoto.self, CalendarEvent.self, BudgetSettings.self, BudgetItem.self],
            inMemory: true
        )
}
