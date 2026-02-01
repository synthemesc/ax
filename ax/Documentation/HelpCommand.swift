//
//  HelpCommand.swift
//  ax
//
//  Dispatcher for ax help subcommands.
//
//  Subcommands:
//    ax help              - Overview (same as ax --help)
//    ax help roles        - Role reference
//    ax help actions      - Action reference
//    ax help attributes   - Output field reference
//    ax help keys         - Key names for ax key
//    ax help --json       - Machine-readable documentation
//

import Foundation

/// Handles the `ax help` command and its subcommands
struct HelpCommand {

    enum Topic: String {
        case roles
        case actions
        case attributes
        case keys
    }

    struct HelpArgs {
        var topic: Topic?
        var json: Bool = false
    }

    static func run(args: HelpArgs) {
        if args.json {
            outputJSON()
            return
        }

        guard let topic = args.topic else {
            // No topic specified - show general help
            // This is handled by main.swift printing helpText
            return
        }

        switch topic {
        case .roles:
            print(RolesDoc.text)
        case .actions:
            print(ActionsDoc.text)
        case .attributes:
            print(AttributesDoc.text)
        case .keys:
            print(KeysDoc.text)
        }

        exit(0)
    }

    /// Output all documentation as JSON for AI agents
    private static func outputJSON() {
        let docs = DocumentationSchema(
            roles: RolesDoc.entries,
            actions: ActionsDoc.entries,
            attributes: AttributesDoc.entries,
            keys: KeysDoc.entries
        )
        Output.json(docs)
    }
}

// MARK: - JSON Schema Types

struct DocumentationSchema: Encodable {
    let roles: [RoleEntry]
    let actions: [ActionEntry]
    let attributes: [AttributeEntry]
    let keys: [KeyEntry]
}

struct RoleEntry: Encodable {
    let name: String
    let description: String
    let commonActions: [String]
}

struct ActionEntry: Encodable {
    let name: String
    let description: String
    let applicableRoles: [String]
}

struct AttributeEntry: Encodable {
    let name: String
    let type: String
    let description: String
}

struct KeyEntry: Encodable {
    let name: String
    let aliases: [String]
    let description: String
}
