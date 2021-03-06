//
//  Copyright © 2018 HomeKitty. All rights reserved.
//

import Vapor
import FluentPostgreSQL
import Leaf
import LeafErrorMiddleware
import Stripe
import SendGrid

let databaseLogger = DatabaseLogger(database: .psql, handler: PrintLogHandler())

public func configure(_ config: inout Config, env: inout Environment, services: inout Services) throws {
    let sendGridKey = Environment.get("SENDGRID_API_KEY") ?? "SENDGRID_API_KEY"
    _ = Environment.get("STRIPE_API_KEY") ?? "STRIPE_API_KEY"

    let dbHostname = Environment.get("DB_HOSTNAME") ?? "localhost"
    let dbUsername = Environment.get("DB_USER") ?? "test"
    let db = Environment.get("DB_DATABASE") ?? "test"
    let dbPort = Int(Environment.get("DB_PORT") ?? "5432") ?? 5432
    let dbPassword = (Environment.get("DB_PASSWORD") ?? "").isEmpty ? nil : Environment.get("DB_PASSWORD")
    
    // Register providers first
    try services.register(FluentPostgreSQLProvider())
    try services.register(LeafProvider())

    // Stripe
    let sendGridConfig = SendGridConfig(apiKey: sendGridKey)

    services.register(sendGridConfig)

    try services.register(SendGridProvider())

    // Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    // Must set the preferred renderer:
    config.prefer(LeafRenderer.self, for: TemplateRenderer.self)
    config.prefer(LeafRenderer.self, for: ViewRenderer.self)

    services.register { worker in
        return LeafErrorMiddleware(environment: worker.environment)
    }

    // Register middleware
    var middlewares = MiddlewareConfig()
    middlewares.use(FileMiddleware.self)
    middlewares.use(LeafErrorMiddleware.self)
    services.register(middlewares)

    // Configure a PostgreSQL database
    var databases = DatabasesConfig()
    let dbConfig = PostgreSQLDatabaseConfig(hostname: dbHostname, port: dbPort, username: dbUsername, database: db, password: dbPassword)
    databases.add(database: PostgreSQLDatabase(config: dbConfig), as: .psql)
    databases.enableLogging(on: .psql)
    services.register(databases)

    let poolConfig = DatabaseConnectionPoolConfig(maxConnections: 18)
    services.register(poolConfig)

    let nioServerConfig = NIOServerConfig.default(hostname: "0.0.0.0", port: Int(Environment.get("PORT") ?? "") ?? 8080, workerCount: 1)
    services.register(nioServerConfig)

    // Configure migrations
    var migrations = MigrationConfig()
    migrations.add(model: Category.self, database: .psql)
    migrations.add(model: Manufacturer.self, database: .psql)
    migrations.add(model: Accessory.self, database: .psql)
    migrations.add(model: Region.self, database: .psql)
    migrations.add(model: HomeKitApp.self, database: .psql)
    migrations.add(model: AccessoryRegionPivot.self, database: .psql)

    services.register(migrations)
}
