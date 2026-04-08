import { BottomBar, Slide } from '@deckio/deck-engine'
import styles from './DbMigrateTargetSlide.module.css'

export default function DbMigrateTargetSlide({ index, project }) {
  return (
    <Slide index={index} className={styles.dbMigrateTarget}>
      <div className="accent-bar" />
      <div className={`orb ${styles.orb1}`} />
      <div className={`orb ${styles.orb2}`} />

      <div className={`${styles.body} content-frame content-gutter`}>
        <div className={styles.header}>
          <p className={styles.eyebrow}>Step 33</p>
          <h2>Target <span className={styles.highlight}>Server</span></h2>
          <p className={styles.subtitle}>
            Verify the Azure Database for PostgreSQL target
          </p>
        </div>

        <div className={styles.columns}>
          <div className={styles.left}>
            <div className={styles.instructions}>
              <p>The <strong>target server</strong> details are pre-populated from the flexible server you opened the migration wizard on:</p>
              <ul className={styles.list}>
                <li>Resource group: <strong>rg-migration-target</strong></li>
                <li>Location: <strong>swedencentral</strong></li>
                <li>PostgreSQL version: <strong>16</strong></li>
                <li>Administrator login: <strong>pgadmin</strong></li>
              </ul>
              <p>Enter the password <strong>P@ssw0rd1234!</strong> for the target server and click <strong>Connect to target</strong> to verify connectivity.</p>
            </div>
          </div>

          <div className={styles.right}>
            <img
              src="/dbmigrate-target.png"
              alt="Target server configuration"
              className={styles.screenshot}
            />
          </div>
        </div>
      </div>

      <BottomBar text="azure-migrate-workshop" />
    </Slide>
  )
}
