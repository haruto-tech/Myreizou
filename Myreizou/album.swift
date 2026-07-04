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

    @State private var isShowingAddFolder = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            if folders.isEmpty {
                ContentUnavailableView(
                    "アルバムファイルがありません",
                    systemImage: "folder.badge.plus",
                    description: Text("右下の＋からファイルを作成できます。")
                )
                .padding(.top, 80)
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(folders) { folder in
                        NavigationLink {
                            AlbumFolderDetailView(folder: folder)
                        } label: {
                            AlbumFolderGridItem(folder: folder)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("アルバム")
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
            ZStack {
                if let coverPhoto = sortedPhotos.first {
                    AlbumImage(data: coverPhoto.imageData)
                        .aspectRatio(1, contentMode: .fill)
                } else {
                    ZStack {
                        Rectangle()
                            .fill(Color(.secondarySystemGroupedBackground))

                        Image(systemName: "folder")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                    }
                    .aspectRatio(1, contentMode: .fill)
                }
            }
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 8))

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
        .sheet(item: $selectedPhoto) { photo in
            AlbumPhotoDetailView(photo: photo)
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
        AlbumImage(data: photo.imageData)
            .aspectRatio(1, contentMode: .fill)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct AlbumPhotoDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let photo: AlbumPhoto

    @State private var isShowingDeleteConfirmation = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    AlbumImage(data: photo.imageData, contentMode: .fit)
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    Label(photo.createdAt.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if !photo.memo.isEmpty {
                        Text(photo.memo)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("写真")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) {
                        isShowingDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                    }
                    .accessibilityLabel("写真を削除")
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
            for: [FoodItem.self, FoodCategory.self, AlbumEntry.self, AlbumFolder.self, AlbumPhoto.self],
            inMemory: true
        )
}
