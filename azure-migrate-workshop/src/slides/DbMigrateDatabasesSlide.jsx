import { BottomBar, Slide } from '@deckio/deck-engine'
import styles from './DbMigrateDatabasesSlide.module.css'

export default function DbMigrateDatabasesSlide({ index, project }) {
  return (
    <Slide index={index} className={styles.dbMigrateDatabases}>
      <div className="accent-bar" />
      <div className={`orb ${styles.orb1}`} />
      <div className={`orb ${styles.orb2}`} />

      <div className={`${styles.body} content-frame content-gutter`}>
        <div className={styles.header}>
          <p className={styles.eyebrow}>Step 34</p>
          <h2>Select <span className={styles.highlight}>Databases</span></h2>
          <p className={styles.subtitle}>
            Choose which databases to validate and migrate
          </p>
        </div>

        <div className={styles.columns}>
          <div className={styles.left}>
            <div className={styles.instructions}>
              <p>The wizard discovers all databases on the source server. Select the databases you want to migrate.</p>
              <p>For this workshop, select the <strong>webapp</strong> database and leave <strong>postgres</strong> unchecked.</p>
              <p>You can migrate up to 8 databases in a single migration run.</p>
            </div>
          </div>

          <div className={styles.right}>
            <img
              src="/dbmigrate-databases.png"
              alt="Select databases to migrate"
              className={styles.screenshot}
            />
          </div>
        </div>
      </div>

      <BottomBar text="azure-migrate-workshop" />
    </Slide>
  )
}
