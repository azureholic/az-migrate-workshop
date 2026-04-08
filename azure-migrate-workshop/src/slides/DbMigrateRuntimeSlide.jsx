import { BottomBar, Slide } from '@deckio/deck-engine'
import styles from './DbMigrateRuntimeSlide.module.css'

export default function DbMigrateRuntimeSlide({ index, project }) {
  return (
    <Slide index={index} className={styles.dbMigrateRuntime}>
      <div className="accent-bar" />
      <div className={`orb ${styles.orb1}`} />
      <div className={`orb ${styles.orb2}`} />

      <div className={`${styles.body} content-frame content-gutter`}>
        <div className={styles.header}>
          <p className={styles.eyebrow}>Step 30</p>
          <h2>Runtime <span className={styles.highlight}>Server</span></h2>
          <p className={styles.subtitle}>
            Configure the runtime server that performs the migration
          </p>
        </div>

        <div className={styles.columns}>
          <div className={styles.left}>
            <div className={styles.instructions}>
              <p>A <strong>runtime server</strong> is required when the source has a private endpoint or private IP address.</p>
              <p>Select <strong>Yes</strong> for "Use runtime server" and configure:</p>
              <ul className={styles.list}>
                <li>Resource group: <strong>rg-migration-target</strong></li>
                <li>Server name: the pre-deployed runtime server</li>
                <li>Virtual network: <strong>vnet-migrate-target</strong></li>
                <li>Subnet: <strong>snet-postgres-migrate</strong></li>
              </ul>
              <p className={styles.warning}>⚠️ Delete the runtime server after migration to avoid ongoing costs.</p>
            </div>
          </div>

          <div className={styles.right}>
            <img
              src="/dbmigrate-runtime.png"
              alt="Runtime server configuration"
              className={styles.screenshot}
            />
          </div>
        </div>
      </div>

      <BottomBar text="azure-migrate-workshop" />
    </Slide>
  )
}
