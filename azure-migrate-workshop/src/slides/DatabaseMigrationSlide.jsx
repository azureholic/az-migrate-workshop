import { BottomBar, Slide } from '@deckio/deck-engine'
import styles from './DatabaseMigrationSlide.module.css'

export default function DatabaseMigrationSlide({ index, project }) {
  return (
    <Slide index={index} className={styles.databaseMigration}>
      <div className="accent-bar" />
      <div className={`orb ${styles.orb1}`} />
      <div className={`orb ${styles.orb2}`} />

      <div className={`${styles.body} content-frame content-gutter`}>
        <div className={styles.center}>
          <p className={styles.eyebrow}>Chapter</p>
          <h2>Database <span className={styles.highlight}>Migration</span></h2>
        </div>
      </div>

      <BottomBar text="azure-migrate-workshop" />
    </Slide>
  )
}
