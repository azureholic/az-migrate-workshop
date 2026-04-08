import { BottomBar, Slide } from '@deckio/deck-engine'
import styles from './DbMigrateSetupSlide.module.css'

export default function DbMigrateSetupSlide({ index, project }) {
  return (
    <Slide index={index} className={styles.dbMigrateSetup}>
      <div className="accent-bar" />
      <div className={`orb ${styles.orb1}`} />
      <div className={`orb ${styles.orb2}`} />

      <div className={`${styles.body} content-frame content-gutter`}>
        <div className={styles.header}>
          <p className={styles.eyebrow}>Step 30</p>
          <h2>Migration <span className={styles.highlight}>Setup</span></h2>
          <p className={styles.subtitle}>
            Configure the PostgreSQL migration wizard
          </p>
        </div>

        <div className={styles.columns}>
          <div className={styles.left}>
            <div className={styles.instructions}>
              <p>Open the <strong>Migration</strong> blade on the target PostgreSQL flexible server and start a new migration.</p>
              <p>Fill in the setup details:</p>
              <ul className={styles.list}>
                <li>Migration name: <strong>webdb</strong></li>
                <li>Source server type: <strong>On-premises server</strong></li>
                <li>Migration option: <strong>Validate and migrate</strong></li>
                <li>Migration mode: <strong>Offline</strong></li>
              </ul>
            </div>
          </div>

          <div className={styles.right}>
            <img
              src="/dbmigrate-setup.png"
              alt="Migration setup wizard"
              className={styles.screenshot}
            />
          </div>
        </div>
      </div>

      <BottomBar text="azure-migrate-workshop" />
    </Slide>
  )
}
