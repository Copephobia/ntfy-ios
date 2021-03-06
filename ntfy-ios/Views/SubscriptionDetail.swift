//
//  SubscriptionDetail.swift
//  ntfy.sh
//
//  Created by Andrew Cope on 1/15/22.
//

import SwiftUI

enum ActiveAlert {
    case clear, unsubscribe, selected
}

struct SubscriptionDetail: View {
    @ObservedObject var subscription: NtfySubscription

    @State private var editMode = EditMode.inactive
    @State private var selection = Set<NtfyNotification>()

    @State private var showAlert = false
    @State private var activeAlert: ActiveAlert = .clear

    @ObservedObject var viewModel = SubscriptionDetailViewModel()

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        let user = Database.current.findUsers(baseUrl: subscription.baseUrl).first
        NavigationView {
            List(selection: $selection) {
                ForEach(subscription.notifications, id: \.self) { notification in
                    NotificationRow(notification: notification)
                }
            }
        }
        .listStyle(PlainListStyle())
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.editMode, self.$editMode)
        .navigationBarBackButtonHidden(self.editMode == .active)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(subscription.displayName()).font(.headline)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                if (self.editMode == .active) {
                    editButton
                } else {
                    Menu("Edit") {
                        editButton
                        Button("Send Test Notification") {
                            let possibleTags = ["warning", "skull", "success", "triangular_flag_on_post", "de", "us", "dog", "cat", "rotating_light", "bike", "backup", "rsync", "this-s-a-tag", "ios"]
                            let priority = Int.random(in: 1..<6)
                            let tags = Array(possibleTags.shuffled().prefix(Int.random(in: 0..<4)))
                            ApiService.shared.publish(
                                subscription: subscription,
                                message: "This is a test notification from the Ntfy iOS app. It has a priority of \(priority). If you send another one, it may look different.",
                                title: "Test: You can set a title if you like",
                                priority: priority,
                                tags: tags,
                                user: user
                            ) { _,_ in
                                print("Success")
                            }
                        }
                        Button("Clear All Notifications") {
                            self.showAlert = true
                            self.activeAlert = .clear
                        }
                        Button("Unsubscribe") {
                            self.showAlert = true
                            self.activeAlert = .unsubscribe
                        }

                    }
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                if (self.editMode == .active) {
                    Button(action: {
                        self.showAlert = true
                        self.activeAlert = .selected
                    }) {
                        Text("Delete")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .alert(isPresented: $showAlert) {
            switch activeAlert {
            case .clear:
                return Alert(
                    title: Text("Clear Notifications"),
                    message: Text("Do you really want to delete all of the notifications in this topic?"),
                    primaryButton: .destructive(
                        Text("Permanently Delete"),
                        action: {
                            Database.current.deleteNotificationsForSubscription(subscription: subscription)
                            //viewModel.notifications = Database.current.getNotifications(subscription: subscription)
                            subscription.loadNotifications()
                        }),
                    secondaryButton: .cancel())
            case .unsubscribe:
                return Alert(
                    title: Text("Unsubscribe"),
                    message: Text("Do you really want to unsubscribe from this topic and delete all of the notifications you received?"),
                    primaryButton: .destructive(
                        Text("Unsubscribe"),
                        action: {
                            Database.current.deleteSubscription(subscription: subscription)
                            self.presentationMode.wrappedValue.dismiss()
                        }),
                    secondaryButton: .cancel())
            case .selected:
                return Alert(
                    title: Text("Delete"),
                    message: Text("Do you really want to delete these selected notifications?"),
                    primaryButton: .destructive(
                        Text("Delete"),
                        action: {
                            deleteSelectedNotifications(notifications: subscription.notifications)
                            self.editMode = .inactive
                        }),
                    secondaryButton: .cancel())
            }
        }
        .overlay(Group {
            if subscription.notifications.isEmpty {
                Text("No Notifications")
                    .font(.headline)
                    .foregroundColor(.gray)
            }
        })
        .refreshable {
            subscription.fetchNewNotifications(user: user, completionHandler: nil)
        }
        .onAppear {
            subscription.loadNotifications()
        }
    }

    private var editButton: some View {
        if editMode == .inactive {
            return Button(action: {
                self.editMode = .active
                self.selection = Set<NtfyNotification>()
            }) {
                Text("Select Messages")
            }
        } else {
            return Button(action: {
                self.editMode = .inactive
                self.selection = Set<NtfyNotification>()
            }) {
                Text("Done")
            }
        }
    }

    private func deleteSelectedNotifications(notifications: [NtfyNotification]) {
        for id in selection {
            if let index = subscription.notifications.lastIndex(where: { $0 == id }) {
                subscription.notifications.remove(at: index)
                Database.current.deleteNotification(notification: notifications[index])
            }
        }
        selection = Set<NtfyNotification>()
    }
}

class SubscriptionDetailViewModel: ObservableObject {
    @Published var notifications = [NtfyNotification]()

    func loadNotifications(subscription: NtfySubscription) {
        notifications = Database.current.getNotifications(subscription: subscription)
    }

    func fetchNewNotifications(subscription: NtfySubscription, user: NtfyUser?) {
        subscription.fetchNewNotifications(user: user) { (_, _) in
            self.loadNotifications(subscription: subscription)
        }
    }
}
