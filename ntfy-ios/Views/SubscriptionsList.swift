//
//  ContentView.swift
//  ntfy-ios
//
//  Created by Andrew Cope on 1/15/22.
//

import SwiftUI

struct SubscriptionsList: View {
    @State var subscriptions = Database.current.getSubscriptions()

    @Binding var addingSubscription: Bool

    var body: some View {
        NavigationView {
            List(subscriptions) { subscription in
                ZStack {
                    NavigationLink(
                        destination: SubscriptionDetail(subscription: subscription)
                    ) {
                        EmptyView()
                    }
                    .opacity(0.0)
                    .buttonStyle(PlainButtonStyle())

                    SubscriptionRow(subscription: subscription)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        subscription.delete()
                        subscriptions = Database.current.getSubscriptions()
                    } label: {
                        Label("Delete", systemImage: "trash.circle")
                    }
                }
            }
            .listStyle(PlainListStyle())
            .navigationTitle("Subscribed Topics")
            .toolbar {
                Button(action: {
                    addingSubscription = true
                }) {
                    Image(systemName: "plus")
                }
            }
            .overlay(Group {
                if subscriptions.isEmpty {
                    Text("No Topics")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
            })
        }.navigationViewStyle(StackNavigationViewStyle())
    }
}
