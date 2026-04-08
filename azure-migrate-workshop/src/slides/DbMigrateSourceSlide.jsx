import { BottomBar, Slide } from '@deckio/deck-engine'
import styles from './DbMigrateSourceSlide.module.css'

export default function DbMigrateSourceSlide({ index, project }) {
  return (
    <Slide index={index} className={styles.dbMigrateSource}>
      <div className="accent-bar" />
      <div className={`orb ${styles.orb1}`} />
      <div className={`orb ${styles.orb2}`} />

      <div className={`${styles.body} content-frame content-gutter`}>
        <div className={styles.header}>
          <p className={styles.eyebrow}>Step 32</p>
          <h2>Source <span className={styles.highlight}>Server</span></h2>
          <p className={styles.subtitle}>
            Connect to the on-premises PostgreSQL source
          </p>
        </div>

        <div className={styles.columns}>
          <div className={styles.left}>
            <div className={styles.instructions}>
              <p>Enter the <strong>source server</strong> connection details for the on-premises PostgreSQL instance:</p>
              <ul className={styles.list}>
                <li>Server name: <strong>10.0.0.4</strong></li>
                <li>Port: <strong>5432</strong></li>
                <li>Administrator login: <strong>webadmin</strong></li>
                <li>Password: <strong>webadmin123</strong></li>
                <li>SSL mode: <strong>Prefer</strong></li>
              </ul>
              <p>Click <strong>Connect to source</strong> and wait for the connectivity test to complete.</p>
            </div>
          </div>

          <div className={styles.right}>
            <img
              src="/dbmigrate-source.png"
              alt="Source server configuration"
              className={styles.screenshot}
            />
          </div>
        </div>
      </div>

      <BottomBar text="azure-migrate-workshop" />
    </Slide>
  )
}
